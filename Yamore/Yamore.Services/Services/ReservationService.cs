using System;
using System.Globalization;
using MapsterMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
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
        private readonly IHttpContextAccessor? _httpContextAccessor;

        public ReservationService(
            _220245Context context,
            IMapper mapper,
            INotificationService notifications,
            IHttpContextAccessor? httpContextAccessor = null)
            : base(context, mapper)
        {
            _notifications = notifications;
            _httpContextAccessor = httpContextAccessor;
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
            if (result.Count > 0)
            {
                var ids = list.Select(x => x.ReservationId).ToList();
                var paid = Context.Set<Database.Payment>().AsNoTracking()
                    .Where(p => ids.Contains(p.ReservationId) && p.Amount > 0)
                    .Select(p => p.ReservationId)
                    .Distinct()
                    .ToHashSet();
                foreach (var m in result)
                    m.IsPaid = paid.Contains(m.ReservationId);
            }

            return new PagedResponse<Model.Reservation>
            {
                Count = count,
                ResultList = result
            };
        }

        public override Model.Reservation GetById(int id)
        {
            var m = base.GetById(id);
            if (m == null)
                return null!;
            if (!CurrentUserMayViewReservation(m))
                return null!;
            m.IsPaid = HasRecordedPayment(id);
            return m;
        }

        /// <summary>
        /// Admins: any row. Yacht owners: own booking or reservation on own yacht. Others: own booking only.
        /// </summary>
        private bool CurrentUserMayViewReservation(Model.Reservation m)
        {
            var http = _httpContextAccessor?.HttpContext;
            if (http?.User?.IsInRole(AppRoles.Admin) == true)
                return true;
            if (!int.TryParse(http?.User?.FindFirstValue(ClaimTypes.NameIdentifier), out var uid))
                return false;
            if (m.UserId == uid)
                return true;
            if (http.User.IsInRole(AppRoles.YachtOwner))
            {
                return Context.Set<Database.Yacht>().AsNoTracking()
                    .Any(y => y.YachtId == m.YachtId && y.OwnerId == uid);
            }

            return false;
        }

        private bool HasRecordedPayment(int reservationId) =>
            Context.Set<Database.Payment>().AsNoTracking()
                .Any(p => p.ReservationId == reservationId && p.Amount > 0);

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
            var http = _httpContextAccessor?.HttpContext;

            if (http?.User?.IsInRole(AppRoles.Admin) == true)
            {
                if (search?.ReservationId != null)
                    filteredQurey = filteredQurey.Where(x => x.ReservationId == search.ReservationId);
                if (search?.UserId != null)
                    filteredQurey = filteredQurey.Where(x => x.UserId == search.UserId);
                if (search?.YachtId != null)
                    filteredQurey = filteredQurey.Where(x => x.YachtId == search.YachtId);
                if (!string.IsNullOrWhiteSpace(search?.Status))
                    filteredQurey = filteredQurey.Where(x => x.Status == search.Status);
                return filteredQurey;
            }

            if (!int.TryParse(http?.User?.FindFirstValue(ClaimTypes.NameIdentifier), out var userId))
                return filteredQurey.Where(_ => false);

            if (http.User.IsInRole(AppRoles.YachtOwner))
            {
                filteredQurey = filteredQurey.Where(r =>
                    r.UserId == userId || r.Yacht.OwnerId == userId);
            }
            else
            {
                filteredQurey = filteredQurey.Where(r => r.UserId == userId);
            }

            if (search?.ReservationId != null)
                filteredQurey = filteredQurey.Where(x => x.ReservationId == search.ReservationId);
            if (search?.YachtId != null)
                filteredQurey = filteredQurey.Where(x => x.YachtId == search.YachtId);
            if (!string.IsNullOrWhiteSpace(search?.Status))
                filteredQurey = filteredQurey.Where(x => x.Status == search.Status);

            return filteredQurey;
        }

        public override Model.Reservation Insert(ReservationInsertRequest request)
        {
            var http = _httpContextAccessor?.HttpContext;
            if (!int.TryParse(http?.User?.FindFirstValue(ClaimTypes.NameIdentifier), out var userId))
                throw new ForbiddenException("You must be signed in to create a reservation.");

            var yachtId = request.YachtId;
            var start = CharterDateNormalizer.ToCharterInstant(request.StartDate);
            var end = CharterDateNormalizer.ToCharterInstant(request.EndDate);
            var serviceIds = request.ServiceIds ?? new List<int>();

            var yacht = Context.Set<Database.Yacht>().AsNoTracking().FirstOrDefault(y => y.YachtId == yachtId);
            if (yacht == null)
                throw new NotFoundException($"Yacht with id {yachtId} not found.");
            if (!string.Equals(yacht.StateMachine, "active", StringComparison.OrdinalIgnoreCase))
            {
                throw new UserException(
                    "This yacht is not available for booking. Only published (active) yachts can be reserved.");
            }

            if (HasOverlap(yachtId, start, end))
                throw new UserException("This yacht is already reserved for the selected dates. Please choose different dates or times.");

            var total = ComputeQuotedTotalForCardBooking(yachtId, start, end, serviceIds);
            var now = DateTime.UtcNow;

            using var tx = Context.Database.BeginTransaction();
            try
            {
                var entity = new Database.Reservation
                {
                    UserId = userId,
                    YachtId = yachtId,
                    StartDate = start,
                    EndDate = end,
                    TotalPrice = total,
                    Status = ReservationStatuses.Pending,
                    CreatedAt = now,
                };
                ApplyStatusAudit(entity, userId, now, "Created");
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

                var model = MapToModel(entity);
                TryNotifyNewPendingReservation(model, yacht);
                return model;
            }
            catch
            {
                tx.Rollback();
                throw;
            }
        }

        public Model.Reservation Reschedule(int id, DateTime newStart, DateTime newEnd)
        {
            newStart = CharterDateNormalizer.ToCharterInstant(newStart);
            newEnd = CharterDateNormalizer.ToCharterInstant(newEnd);

            var http = _httpContextAccessor?.HttpContext;
            if (!int.TryParse(http?.User?.FindFirstValue(ClaimTypes.NameIdentifier), out var bookerId))
                throw new ForbiddenException("You must be signed in to reschedule a reservation.");

            if (newEnd <= newStart)
                throw new UserException("End date must be after the start date.");

            var entity = LoadReservationWithYacht(id);

            if (entity.UserId != bookerId)
                throw new ForbiddenException("You may only reschedule your own reservations.");

            if (ReservationStatuses.IsTerminal(entity.Status))
                throw new UserException("Completed or cancelled reservations cannot be rescheduled.");

            var status = entity.Status ?? string.Empty;
            if (!string.Equals(status, ReservationStatuses.Pending, StringComparison.OrdinalIgnoreCase)
                && !string.Equals(status, ReservationStatuses.Confirmed, StringComparison.OrdinalIgnoreCase))
            {
                throw new UserException("Only pending or confirmed reservations can be rescheduled.");
            }

            if (HasFinalizedPayment(entity.ReservationId, entity.Status))
            {
                throw new UserException(
                    "Paid reservations cannot be rescheduled. Please contact support if you need to change your travel dates.");
            }

            if (HasOverlapExcluding(entity.YachtId, newStart, newEnd, entity.ReservationId))
                throw new UserException("This yacht is already reserved for the selected dates. Please choose different dates or times.");

            var serviceIds = Context.Set<Database.ReservationService>().AsNoTracking()
                .Where(rs => rs.ReservationId == id)
                .Select(rs => rs.ServiceId)
                .ToList();

            var total = ComputeQuotedTotalForCardBooking(
                entity.YachtId, newStart, newEnd, serviceIds, entity.ReservationId);
            var now = DateTime.UtcNow;
            var period =
                $"{entity.StartDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)} – {entity.EndDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)}";
            var newPeriod =
                $"{newStart.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)} – {newEnd.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)}";

            entity.StartDate = newStart;
            entity.EndDate = newEnd;
            entity.TotalPrice = total;
            ApplyStatusAudit(entity, bookerId, now, $"Rescheduled ({period} → {newPeriod})");
            Context.SaveChanges();
            return Mapper.Map<Model.Reservation>(entity);
        }

        public override Model.Reservation Update(int id, ReservationUpdateRequest request) =>
            throw new UserException(
                "Reservations cannot be updated with PUT. Use cancel, confirm, reject, complete, or PUT .../reschedule.");

        public override Model.Reservation Delete(int id) =>
            throw new UserException("Reservations cannot be deleted. Cancel the booking instead.");

        public decimal ValidateAndQuoteCardBooking(int yachtId, DateTime start, DateTime end, IReadOnlyList<int> serviceIds)
        {
            serviceIds ??= Array.Empty<int>();
            return ComputeQuotedTotalForCardBooking(yachtId, start, end, serviceIds);
        }

        public Model.Reservation InsertConfirmedReservationWithServices(
            int userId,
            int yachtId,
            DateTime startDate,
            DateTime endDate,
            IReadOnlyList<int> serviceIds,
            CardPaymentPendingInfo? recordPendingCardPayment = null)
        {
            startDate = CharterDateNormalizer.ToCharterInstant(startDate);
            endDate = CharterDateNormalizer.ToCharterInstant(endDate);
            serviceIds ??= Array.Empty<int>();
            var quoted = ComputeQuotedTotalForCardBooking(yachtId, startDate, endDate, serviceIds);
            if (recordPendingCardPayment != null && Math.Abs(recordPendingCardPayment.Amount - quoted) > 0.02m)
            {
                throw new InvalidOperationException("Payment amount does not match the server-calculated booking total.");
            }

            using var tx = Context.Database.BeginTransaction();
            try
            {
                if (HasOverlap(yachtId, startDate, endDate))
                {
                    throw new UserException(
                        "This yacht is already reserved for the selected dates. Please choose different dates or times.");
                }

                var now = DateTime.UtcNow;
                var entity = new Database.Reservation
                {
                    UserId = userId,
                    YachtId = yachtId,
                    StartDate = startDate,
                    EndDate = endDate,
                    TotalPrice = quoted,
                    Status = ReservationStatuses.Confirmed,
                    CreatedAt = now,
                };
                ApplyStatusAudit(entity, userId, now, "Paid card booking");

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

                if (recordPendingCardPayment != null)
                {
                    var payAt = recordPendingCardPayment.PaymentDateUtc ?? DateTime.UtcNow;
                    Context.Add(new Database.Payment
                    {
                        ReservationId = entity.ReservationId,
                        Amount = recordPendingCardPayment.Amount,
                        PaymentDate = payAt,
                        PaymentMethod = recordPendingCardPayment.PaymentMethod,
                        Status = PaymentStatuses.DbStatusForSuccessfulCharge(),
                    });
                    Context.SaveChanges();
                }
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
                // Inline (see ReservationStatuses.BlocksAvailability): not cancelled/completed, including null. Must be translatable to SQL (no custom C# in Where).
                .Where(r => r.Status == null
                    || (r.Status != ReservationStatuses.Cancelled
                        && r.Status != ReservationStatuses.Completed))
                .Any(r => start < r.EndDate && end > r.StartDate);

        private bool HasOverlapExcluding(int yachtId, DateTime start, DateTime end, int excludeReservationId) =>
            Context.Set<Database.Reservation>()
                .AsNoTracking()
                .Where(r => r.YachtId == yachtId && r.ReservationId != excludeReservationId)
                .Where(r => r.Status == null
                    || (r.Status != ReservationStatuses.Cancelled
                        && r.Status != ReservationStatuses.Completed))
                .Any(r => start < r.EndDate && end > r.StartDate);

        private decimal ComputeQuotedTotalForCardBooking(
            int yachtId,
            DateTime start,
            DateTime end,
            IReadOnlyList<int> serviceIds,
            int? excludeReservationId = null)
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

            var overlaps = excludeReservationId.HasValue
                ? HasOverlapExcluding(yachtId, start, end, excludeReservationId.Value)
                : HasOverlap(yachtId, start, end);
            if (overlaps)
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

        /// <summary>Billable day count; matches Flutter <c>end.difference(start).inDays</c> (whole 24h periods, floored), minimum 1.</summary>
        private static int GetBookingDurationDays(DateTime start, DateTime end)
        {
            if (end <= start)
            {
                return 1;
            }

            var span = end - start;
            var days = (int)Math.Floor(span.TotalDays);
            if (days < 1)
            {
                days = 1;
            }

            return Math.Min(365, days);
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
            var confirmed = Mapper.Map<Model.Reservation>(entity);
            _notifications.InsertUserNotification(
                entity.UserId,
                "Booking confirmed",
                BuildConfirmGuestMessage(entity));
            return confirmed;
        }

        public void ApplyCardPaymentConfirmation(Database.Reservation entity, int? paidByUserId)
        {
            if (string.Equals(entity.Status, ReservationStatuses.Confirmed, StringComparison.OrdinalIgnoreCase))
                return;

            if (ReservationStatuses.IsTerminal(entity.Status))
                throw new InvalidOperationException("Reservation is not in a state that can be paid for.");

            if (!string.Equals(entity.Status, ReservationStatuses.Pending, StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Only pending reservations can be confirmed by card payment.");

            ApplyStatusAudit(entity, paidByUserId, DateTime.UtcNow, "Card payment succeeded");
            entity.Status = ReservationStatuses.Confirmed;
        }

        public CancelReservationOutcome Cancel(int id, int actorUserId, bool actorIsAdmin, string? cancellationMessage)
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

            if (HasCardPayment(entity.ReservationId))
            {
                throw new UserException(
                    "Paid reservations cannot be cancelled automatically. Please contact an administrator for a manual review and refund process.");
            }

            var cancellingAsCounterparty = (actorIsAdmin || isOwner) && entity.UserId != actorUserId;
            if (cancellingAsCounterparty && string.IsNullOrWhiteSpace(cancellationMessage))
            {
                throw new UserException(
                    "A cancellation reason is required when cancelling a guest's booking as an administrator or yacht owner.");
            }

            var auditReason = string.IsNullOrWhiteSpace(cancellationMessage)
                ? "Cancelled"
                : cancellationMessage.Trim();
            ApplyStatusAudit(entity, actorUserId, DateTime.UtcNow, auditReason);
            entity.Status = ReservationStatuses.Cancelled;
            Context.SaveChanges();

            if (isGuest && !actorIsAdmin)
                _notifications.InsertUserNotification(
                    entity.Yacht.OwnerId,
                    "Booking cancelled",
                    BuildOwnerCancelMessage(entity));
            else if ((isOwner || actorIsAdmin) && entity.UserId != actorUserId)
            {
                var guestNote = auditReason.Length > 400 ? auditReason[..400] + "…" : auditReason;
                _notifications.InsertUserNotification(
                    entity.UserId,
                    "Booking cancelled",
                    BuildGuestNotifiedOnOwnerOrAdminCancelMessage(entity, guestNote));
            }

            return new CancelReservationOutcome
            {
                Reservation = Mapper.Map<Model.Reservation>(entity),
                HadCardPayment = false,
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
                "Booking declined",
                BuildRejectionNotificationMessage(entity, note));

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
            _notifications.InsertUserNotification(
                entity.UserId,
                "Trip completed",
                BuildTripCompletedMessage(entity, forGuest: true));
            _notifications.InsertUserNotification(
                entity.Yacht.OwnerId,
                "Trip completed",
                BuildTripCompletedMessage(entity, forGuest: false));
            return Mapper.Map<Model.Reservation>(entity);
        }

        private Database.Reservation LoadReservationWithYacht(int id)
        {
            var entity = Context.Set<Database.Reservation>()
                .Include(r => r.Yacht)
                .FirstOrDefault(r => r.ReservationId == id);
            if (entity == null)
                throw new NotFoundException($"Reservation with id {id} not found.");
            return entity;
        }

        private bool HasCardPayment(int reservationId) =>
            Context.Set<Database.Payment>().AsNoTracking()
                .Any(p => p.ReservationId == reservationId
                          && p.Amount > 0
                          && p.PaymentMethod != null
                          && p.PaymentMethod.ToLower().Contains("card"));

        /// <summary>
        /// True when the booking has a completed card charge (or equivalent settled payment).
        /// Used to lock reschedule after Stripe checkout, per paid-booking rules.
        /// </summary>
        private bool HasFinalizedPayment(int reservationId, string? reservationStatus) =>
            Context.Set<Database.Payment>().AsNoTracking()
                .Any(p => p.ReservationId == reservationId
                    && p.Amount > 0
                    && PaymentStatuses.CountsTowardRevenue(
                        p.Status, p.PaymentMethod, reservationStatus));

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
            foreach (var e in candidates)
            {
                _notifications.InsertUserNotification(
                    e.UserId,
                    "Trip completed",
                    BuildTripCompletedMessage(e, forGuest: true));
                _notifications.InsertUserNotification(
                    e.Yacht.OwnerId,
                    "Trip completed",
                    BuildTripCompletedMessage(e, forGuest: false));
            }
            return candidates.Count;
        }

        private void TryNotifyNewPendingReservation(Model.Reservation r, Database.Yacht yacht)
        {
            var ctx = GetReservationMessageContext(r.UserId, r.YachtId);
            var guest = string.IsNullOrWhiteSpace(ctx.UserDisplayName) ? "A guest" : ctx.UserDisplayName!.Trim();
            var vessel = string.IsNullOrWhiteSpace(ctx.YachtName) ? "a yacht" : ctx.YachtName!.Trim();
            var period = FormatPeriodForModel(r);
            _notifications.InsertUserNotification(
                yacht.OwnerId,
                "New booking request",
                $"{guest} requested {vessel} for {period}. Open Reservations to confirm or cancel.");
            _notifications.InsertUserNotification(
                r.UserId,
                "Request submitted",
                $"Your request for {vessel} ({period}) was sent to the owner. You will be notified when it is confirmed.");
        }

        private static string FormatPeriodForModel(Model.Reservation r) =>
            $"{r.StartDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)} – {r.EndDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)}";

        private static string FormatPeriod(Database.Reservation r) =>
            $"{r.StartDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)} – {r.EndDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)}";

        private string BuildConfirmGuestMessage(Database.Reservation r)
        {
            var ctx = GetReservationMessageContext(r.UserId, r.YachtId);
            var vessel = string.IsNullOrWhiteSpace(ctx.YachtName) ? "the yacht" : ctx.YachtName!.Trim();
            return $"Your booking for {vessel} ({FormatPeriod(r)}) is confirmed.";
        }

        private string BuildTripCompletedMessage(Database.Reservation r, bool forGuest)
        {
            var ctx = GetReservationMessageContext(r.UserId, r.YachtId);
            var vessel = string.IsNullOrWhiteSpace(ctx.YachtName) ? "the yacht" : ctx.YachtName!.Trim();
            if (forGuest)
                return $"You completed your rental of {vessel} ({FormatPeriod(r)}). Thank you for using Yamore.";
            var guest = string.IsNullOrWhiteSpace(ctx.UserDisplayName) ? "A guest" : ctx.UserDisplayName!.Trim();
            return $"Rental to {guest} for {vessel} ({FormatPeriod(r)}) is marked as completed.";
        }

        private string BuildOwnerCancelMessage(Database.Reservation r)
        {
            var ctx = GetReservationMessageContext(r.UserId, r.YachtId);
            var guest = string.IsNullOrWhiteSpace(ctx.UserDisplayName) ? "A guest" : ctx.UserDisplayName.Trim();
            var vessel = string.IsNullOrWhiteSpace(ctx.YachtName) ? "Your listing" : ctx.YachtName.Trim();
            var period = $"{r.StartDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)} – {r.EndDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)}";
            return $"Cancelled: {guest} · {vessel} · {period}";
        }

        private string BuildGuestNotifiedOnOwnerOrAdminCancelMessage(Database.Reservation r, string cancellationReason)
        {
            var ctx = GetReservationMessageContext(r.UserId, r.YachtId);
            var vessel = string.IsNullOrWhiteSpace(ctx.YachtName) ? "the yacht" : ctx.YachtName.Trim();
            var period = $"{r.StartDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)} – {r.EndDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)}";
            return $"Your booking for {vessel} ({period}) was cancelled. Reason: {cancellationReason}";
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
