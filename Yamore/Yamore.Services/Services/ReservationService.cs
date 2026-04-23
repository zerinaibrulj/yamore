using System.Globalization;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Yamore.Model;
using Yamore.Model.Requests.Reservation;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class ReservationService : BaseCRUDService<Model.Reservation, ReservationSearchObject, Database.Reservation, ReservationInsertRequest, ReservationUpdateRequest, ReservationDeleteRequest>, IReservationService
    {
        private readonly INotificationService _notifications;

        public ReservationService(_220245Context context, IMapper mapper, INotificationService notifications)
            : base(context, mapper)
        {
            _notifications = notifications;
        }

        public override PagedResponse<Model.Reservation> GetPaged(ReservationSearchObject search)
        {
            search ??= new ReservationSearchObject();
            search.Page = PagingConstraints.NormalizePage(search.Page);
            search.PageSize = PagingConstraints.NormalizePageSize(search.PageSize);

            var query = Context.Set<Database.Reservation>().AsQueryable();
            query = AddFilter(search, query);
            int count = query.Count();

            query = query.Skip(search.Page!.Value * search.PageSize!.Value).Take(search.PageSize.Value);

            var list = query.ToList();
            var result = list.Select(MapToModel).ToList();

            return new PagedResponse<Model.Reservation>
            {
                Count = count,
                ResultList = result
            };
        }

        private static Model.Reservation MapToModel(Database.Reservation r) => new()
        {
            ReservationId = r.ReservationId,
            UserId = r.UserId,
            YachtId = r.YachtId,
            StartDate = r.StartDate,
            EndDate = r.EndDate,
            TotalPrice = r.TotalPrice,
            Status = r.Status,
            CreatedAt = r.CreatedAt,
            StatusChangedAt = r.StatusChangedAt,
            StatusChangedByUserId = r.StatusChangedByUserId,
            StatusChangeReason = r.StatusChangeReason
        };

        public override IQueryable<Database.Reservation> AddFilter(ReservationSearchObject search, IQueryable<Database.Reservation> query)
        {
            var filteredQurey = base.AddFilter(search, query);

            if (search?.ReservationId != null)
            {
                filteredQurey = filteredQurey.Where(x => x.ReservationId == search.ReservationId);
            }

            if (search?.UserId != null)
            {
                filteredQurey = filteredQurey.Where(x => x.UserId == search.UserId);
            }

            if (search?.YachtId != null)
            {
                filteredQurey = filteredQurey.Where(x => x.YachtId == search.YachtId);
            }

            if (!string.IsNullOrWhiteSpace(search?.Status))
            {
                filteredQurey = filteredQurey.Where(x => x.Status == search.Status);
            }

            return filteredQurey;
        }

        public override void BeforeInsret(ReservationInsertRequest request, Database.Reservation entity)
        {
            var now = DateTime.UtcNow;
            entity.Status = ReservationStatuses.Pending;
            if (entity.CreatedAt == null)
                entity.CreatedAt = now;
            entity.StatusChangedAt = now;
            entity.StatusChangedByUserId = request.UserId;
            entity.StatusChangeReason = "Created";
            base.BeforeInsret(request, entity);
        }

        public override Model.Reservation Insert(ReservationInsertRequest request)
        {
            var yachtId = request.YachtId;
            var start = request.StartDate;
            var end = request.EndDate;

            var yacht = Context.Set<Database.Yacht>().AsNoTracking().FirstOrDefault(y => y.YachtId == yachtId);
            if (yacht == null)
                throw new KeyNotFoundException($"Yacht with id {yachtId} not found.");
            if (!string.Equals(yacht.StateMachine, "active", StringComparison.OrdinalIgnoreCase))
            {
                throw new UserException(
                    "This yacht is not available for booking. Only published (active) yachts can be reserved.");
            }

            if (HasOverlap(yachtId, start, end))
                throw new UserException("This yacht is already reserved for the selected dates. Please choose different dates or times.");

            return base.Insert(request);
        }

        public override Model.Reservation Update(int id, ReservationUpdateRequest request)
        {
            var entity = Context.Set<Database.Reservation>().Find(id);
            if (entity == null)
                throw new KeyNotFoundException($"Reservation with id {id} not found.");

            var preserveStatus = entity.Status;
            var sAt = entity.StatusChangedAt;
            var sBy = entity.StatusChangedByUserId;
            var sReason = entity.StatusChangeReason;

            Mapper.Map(request, entity);

            entity.Status = preserveStatus;
            entity.StatusChangedAt = sAt;
            entity.StatusChangedByUserId = sBy;
            entity.StatusChangeReason = sReason;

            BeforeUpdate(request, entity);
            Context.SaveChanges();
            return Mapper.Map<Model.Reservation>(entity);
        }

        public override Model.Reservation Delete(int id) =>
            throw new UserException("Reservations cannot be deleted. Cancel the booking instead.");

        public decimal ValidateAndQuoteCardBooking(int yachtId, DateTime start, DateTime end, IReadOnlyList<int> serviceIds)
        {
            serviceIds ??= Array.Empty<int>();
            return ComputeQuotedTotalForCardBooking(yachtId, start, end, serviceIds);
        }

        public Model.Reservation InsertConfirmedReservationWithServices(ReservationInsertRequest request, IReadOnlyList<int> serviceIds)
        {
            serviceIds ??= Array.Empty<int>();
            var quoted = ComputeQuotedTotalForCardBooking(request.YachtId, request.StartDate, request.EndDate, serviceIds);
            if (request.TotalPrice == null || Math.Abs(request.TotalPrice.Value - quoted) > 0.02m)
            {
                throw new UserException("Price mismatch. Please refresh and try again.");
            }

            using var tx = Context.Database.BeginTransaction();
            try
            {
                if (HasOverlap(request.YachtId, request.StartDate, request.EndDate))
                {
                    throw new UserException(
                        "This yacht is already reserved for the selected dates. Please choose different dates or times.");
                }

                var entity = Mapper.Map<Database.Reservation>(request);
                var now = DateTime.UtcNow;
                entity.Status = ReservationStatuses.Confirmed;
                entity.CreatedAt ??= now;
                ApplyStatusAudit(entity, request.UserId, now, "Paid card booking");

                Context.Add(entity);
                Context.SaveChanges();

                foreach (var sid in serviceIds.Distinct())
                {
                    Context.Add(new Database.ReservationService
                    {
                        ReservationId = entity.ReservationId,
                        ServiceId = sid,
                    });
                }
                Context.SaveChanges();
                tx.Commit();
                return Mapper.Map<Model.Reservation>(entity);
            }
            catch
            {
                tx.Rollback();
                throw;
            }
        }

        private bool HasOverlap(int yachtId, DateTime start, DateTime end) =>
            Context.Set<Database.Reservation>()
                .AsNoTracking()
                .Where(r => r.YachtId == yachtId)
                .Where(r => ReservationStatuses.BlocksAvailability(r.Status))
                .Any(r => start < r.EndDate && end > r.StartDate);

        private decimal ComputeQuotedTotalForCardBooking(int yachtId, DateTime start, DateTime end, IReadOnlyList<int> serviceIds)
        {
            if (end <= start)
                throw new UserException("End date must be after the start date.");

            var yacht = Context.Set<Database.Yacht>().AsNoTracking().FirstOrDefault(y => y.YachtId == yachtId);
            if (yacht == null)
                throw new UserException("The selected yacht could not be found.");
            if (!string.Equals(yacht.StateMachine, "active", StringComparison.OrdinalIgnoreCase))
            {
                throw new UserException(
                    "This yacht is not available for booking. Only published (active) yachts can be reserved.");
            }

            if (HasOverlap(yachtId, start, end))
            {
                throw new UserException(
                    "This yacht is already reserved for the selected dates. Please choose different dates or times.");
            }

            var durationDays = GetBookingDurationDays(start, end);
            var baseTotal = yacht.PricePerDay * durationDays;
            var distinctIds = serviceIds.Distinct().ToList();
            if (distinctIds.Count == 0)
                return baseTotal;

            var linkedServiceIds = Context.Set<Database.YachtService>().AsNoTracking()
                .Where(ys => ys.YachtId == yachtId && distinctIds.Contains(ys.ServiceId))
                .Select(ys => ys.ServiceId)
                .ToHashSet();

            if (linkedServiceIds.Count != distinctIds.Count)
                throw new UserException("One or more selected services are not available for this yacht.");

            var services = Context.Set<Database.Service>().AsNoTracking()
                .Where(s => distinctIds.Contains(s.ServiceId))
                .Select(s => new { s.ServiceId, s.Price })
                .ToList();

            if (services.Count != distinctIds.Count)
                throw new UserException("Invalid service selected.");

            var servicesTotal = services.Sum(s => s.Price ?? 0m);
            return baseTotal + servicesTotal;
        }

        private static int GetBookingDurationDays(DateTime start, DateTime end)
        {
            var span = end - start;
            var fractionalDays = span.TotalHours / 24.0;
            var days = (int)Math.Ceiling(fractionalDays);
            return Math.Max(1, Math.Min(365, days));
        }

        private static void ApplyStatusAudit(Database.Reservation entity, int? byUserId, DateTime utcNow, string? reason)
        {
            entity.StatusChangedAt = utcNow;
            entity.StatusChangedByUserId = byUserId;
            entity.StatusChangeReason = string.IsNullOrWhiteSpace(reason) ? null : reason.Trim();
            if (entity.StatusChangeReason != null && entity.StatusChangeReason.Length > 500)
                entity.StatusChangeReason = entity.StatusChangeReason[..500];
        }

        public Model.Reservation Confirm(int id, int actorUserId, bool actorIsAdmin, bool actorIsYachtOwner)
        {
            var entity = LoadReservationWithYacht(id);

            if (string.Equals(entity.Status, ReservationStatuses.Confirmed, StringComparison.OrdinalIgnoreCase))
                return Mapper.Map<Model.Reservation>(entity);

            if (ReservationStatuses.IsTerminal(entity.Status))
                throw new UserException("This reservation can no longer be confirmed.");

            if (!string.Equals(entity.Status, ReservationStatuses.Pending, StringComparison.OrdinalIgnoreCase))
                throw new UserException("Only pending reservations can be confirmed.");

            if (actorIsAdmin)
            {
                // allowed
            }
            else if (actorIsYachtOwner && entity.Yacht.OwnerId == actorUserId)
            {
                // allowed
            }
            else
                throw new UnauthorizedAccessException("You are not allowed to confirm this reservation.");

            ApplyStatusAudit(entity, actorUserId, DateTime.UtcNow, "Confirmed");
            entity.Status = ReservationStatuses.Confirmed;
            Context.SaveChanges();
            return Mapper.Map<Model.Reservation>(entity);
        }

        public Model.Reservation ConfirmFromSuccessfulCardPayment(int reservationId, int? paidByUserId)
        {
            var entity = LoadReservationWithYacht(reservationId);

            if (string.Equals(entity.Status, ReservationStatuses.Confirmed, StringComparison.OrdinalIgnoreCase))
                return Mapper.Map<Model.Reservation>(entity);

            if (ReservationStatuses.IsTerminal(entity.Status))
                throw new InvalidOperationException("Reservation is not in a state that can be paid for.");

            if (!string.Equals(entity.Status, ReservationStatuses.Pending, StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Only pending reservations can be confirmed by card payment.");

            ApplyStatusAudit(entity, paidByUserId, DateTime.UtcNow, "Card payment succeeded");
            entity.Status = ReservationStatuses.Confirmed;
            Context.SaveChanges();
            return Mapper.Map<Model.Reservation>(entity);
        }

        public CancelReservationOutcome Cancel(int id, int actorUserId, bool actorIsAdmin, string? reason)
        {
            var entity = LoadReservationWithYacht(id);

            if (string.Equals(entity.Status, ReservationStatuses.Cancelled, StringComparison.OrdinalIgnoreCase))
            {
                return new CancelReservationOutcome
                {
                    Reservation = Mapper.Map<Model.Reservation>(entity),
                    HadCardPayment = HasCardPayment(entity.ReservationId),
                };
            }

            if (string.Equals(entity.Status, ReservationStatuses.Completed, StringComparison.OrdinalIgnoreCase))
                throw new UserException("Completed reservations cannot be cancelled.");

            var isGuest = entity.UserId == actorUserId;
            var isOwner = entity.Yacht.OwnerId == actorUserId;
            if (!actorIsAdmin && !isGuest && !isOwner)
                throw new UnauthorizedAccessException("You are not allowed to cancel this reservation.");

            var hadCardPayment = HasCardPayment(entity.ReservationId);

            ApplyStatusAudit(entity, actorUserId, DateTime.UtcNow, string.IsNullOrWhiteSpace(reason) ? "Cancelled" : reason.Trim());
            entity.Status = ReservationStatuses.Cancelled;
            Context.SaveChanges();

            if (isGuest && !actorIsAdmin)
                _notifications.InsertUserNotification(
                    entity.Yacht.OwnerId,
                    TruncateNotification(BuildOwnerCancelMessage(entity)));
            else if ((isOwner || actorIsAdmin) && entity.UserId != actorUserId)
                _notifications.InsertUserNotification(
                    entity.UserId,
                    TruncateNotification(BuildGuestNotifiedOnOwnerOrAdminCancelMessage(entity)));

            return new CancelReservationOutcome
            {
                Reservation = Mapper.Map<Model.Reservation>(entity),
                HadCardPayment = hadCardPayment,
            };
        }

        public Model.Reservation Reject(int id, int adminUserId, string reason)
        {
            if (string.IsNullOrWhiteSpace(reason))
                throw new UserException("A rejection reason is required.");

            var entity = LoadReservationWithYacht(id);

            if (!string.Equals(entity.Status, ReservationStatuses.Pending, StringComparison.OrdinalIgnoreCase))
                throw new UserException("Only pending reservations can be rejected.");

            var trimmed = reason.Trim();
            ApplyStatusAudit(entity, adminUserId, DateTime.UtcNow, $"Rejected: {trimmed}");
            entity.Status = ReservationStatuses.Cancelled;
            Context.SaveChanges();

            var note = trimmed.Length > 200 ? trimmed[..200] + "…" : trimmed;
            _notifications.InsertUserNotification(
                entity.UserId,
                TruncateNotification(BuildRejectionNotificationMessage(entity, note)));

            return Mapper.Map<Model.Reservation>(entity);
        }

        public Model.Reservation Complete(int id, int actorUserId, bool actorIsAdmin)
        {
            var entity = LoadReservationWithYacht(id);

            if (string.Equals(entity.Status, ReservationStatuses.Completed, StringComparison.OrdinalIgnoreCase))
                return Mapper.Map<Model.Reservation>(entity);

            if (!string.Equals(entity.Status, ReservationStatuses.Confirmed, StringComparison.OrdinalIgnoreCase))
                throw new UserException("Only confirmed reservations can be marked completed.");

            var now = DateTime.UtcNow;
            if (now < entity.EndDate)
                throw new UserException("The trip must have ended before it can be marked completed.");

            var isGuest = entity.UserId == actorUserId;
            var isOwner = entity.Yacht.OwnerId == actorUserId;
            if (!actorIsAdmin && !isGuest && !isOwner)
                throw new UnauthorizedAccessException("You are not allowed to complete this reservation.");

            ApplyStatusAudit(entity, actorUserId, now, "Completed");
            entity.Status = ReservationStatuses.Completed;
            Context.SaveChanges();
            return Mapper.Map<Model.Reservation>(entity);
        }

        private Database.Reservation LoadReservationWithYacht(int id)
        {
            var entity = Context.Set<Database.Reservation>()
                .Include(r => r.Yacht)
                .FirstOrDefault(r => r.ReservationId == id);
            if (entity == null)
                throw new KeyNotFoundException($"Reservation with id {id} not found.");
            return entity;
        }

        private bool HasCardPayment(int reservationId) =>
            Context.Set<Database.Payment>().AsNoTracking()
                .Any(p => p.ReservationId == reservationId
                          && p.Amount > 0
                          && p.PaymentMethod != null
                          && p.PaymentMethod.ToLower().Contains("card"));

        public ReservationMessageContext GetReservationMessageContext(int userId, int yachtId)
        {
            var user = Context.Set<Database.User>().Find(userId);
            var yacht = Context.Set<Database.Yacht>().Find(yachtId);
            return new ReservationMessageContext
            {
                UserEmail = user?.Email,
                UserDisplayName = user == null ? null : $"{user.FirstName} {user.LastName}".Trim(),
                YachtName = yacht?.Name,
            };
        }

        public int AutoCompletePastTrips()
        {
            var now = DateTime.UtcNow;
            var candidates = Context.Set<Database.Reservation>()
                .Include(r => r.Yacht)
                .Where(r => r.Status == ReservationStatuses.Confirmed && now >= r.EndDate)
                .ToList();

            if (candidates.Count == 0)
                return 0;

            foreach (var e in candidates)
            {
                ApplyStatusAudit(e, null, now, "Auto-completed (trip ended)");
                e.Status = ReservationStatuses.Completed;
            }

            Context.SaveChanges();
            return candidates.Count;
        }

        private static string TruncateNotification(string text, int maxLen = 255) =>
            string.IsNullOrEmpty(text) || text.Length <= maxLen
                ? text
                : text.Substring(0, maxLen);

        private string BuildOwnerCancelMessage(Database.Reservation r)
        {
            var ctx = GetReservationMessageContext(r.UserId, r.YachtId);
            var guest = string.IsNullOrWhiteSpace(ctx.UserDisplayName) ? "A guest" : ctx.UserDisplayName.Trim();
            var vessel = string.IsNullOrWhiteSpace(ctx.YachtName) ? "Your listing" : ctx.YachtName.Trim();
            var period = $"{r.StartDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)} – {r.EndDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)}";
            return $"Cancelled: {guest} · {vessel} · {period}";
        }

        private string BuildGuestNotifiedOnOwnerOrAdminCancelMessage(Database.Reservation r)
        {
            var ctx = GetReservationMessageContext(r.UserId, r.YachtId);
            var vessel = string.IsNullOrWhiteSpace(ctx.YachtName) ? "the yacht" : ctx.YachtName.Trim();
            var period = $"{r.StartDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)} – {r.EndDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)}";
            return $"Your booking for {vessel} ({period}) was cancelled.";
        }

        private string BuildRejectionNotificationMessage(Database.Reservation r, string reasonNote)
        {
            var ctx = GetReservationMessageContext(r.UserId, r.YachtId);
            var vessel = string.IsNullOrWhiteSpace(ctx.YachtName) ? "a yacht" : ctx.YachtName.Trim();
            var period = $"{r.StartDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)} – {r.EndDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)}";
            return $"Declined: {vessel} ({period}). Reason: {reasonNote}";
        }
    }
}
