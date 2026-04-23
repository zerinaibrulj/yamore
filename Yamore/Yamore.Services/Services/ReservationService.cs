using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.Requests.Reservation;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Yamore.Services.Services
{
    public class ReservationService : BaseCRUDService<Model.Reservation, ReservationSearchObject, Database.Reservation, ReservationInsertRequest, ReservationUpdateRequest, ReservationDeleteRequest>, IReservationService
    {
        public ReservationService(_220245Context context, IMapper mapper) 
            : base(context, mapper)
        {
        }

        public override PagedResponse<Model.Reservation> GetPaged(ReservationSearchObject search)
        {
            var query = Context.Set<Database.Reservation>().AsQueryable();
            query = AddFilter(search, query);
            int count = query.Count();

            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
                query = query.Skip(search.Page.Value * search.PageSize.Value).Take(search.PageSize.Value);

            var list = query.ToList();
            var result = list.Select(r => new Model.Reservation
            {
                ReservationId = r.ReservationId,
                UserId = r.UserId,
                YachtId = r.YachtId,
                StartDate = r.StartDate,
                EndDate = r.EndDate,
                TotalPrice = r.TotalPrice,
                Status = r.Status,
                CreatedAt = r.CreatedAt
            }).ToList();

            return new PagedResponse<Model.Reservation>
            {
                Count = count,
                ResultList = result
            };
        }

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

            // Check for overlapping reservations for the same yacht (excluding cancelled)
            var overlapping = Context.Set<Database.Reservation>()
                .Where(r => r.YachtId == yachtId && r.Status != null && r.Status != "Cancelled")
                .Any(r => start < r.EndDate && end > r.StartDate);

            if (overlapping)
                throw new InvalidOperationException("This yacht is already reserved for the selected dates. Please choose different dates or times.");

            return base.Insert(request);
        }

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
                entity.Status = "Confirmed";
                if (entity.CreatedAt == null)
                    entity.CreatedAt = DateTime.UtcNow;
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
                .Where(r => r.YachtId == yachtId && r.Status != null && r.Status != "Cancelled")
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
            decimal servicesTotal = 0;
            foreach (var sid in serviceIds.Distinct())
            {
                var available = Context.Set<Database.YachtService>().AsNoTracking()
                    .Any(ys => ys.YachtId == yachtId && ys.ServiceId == sid);
                if (!available)
                {
                    throw new UserException("One or more selected services are not available for this yacht.");
                }
                var svc = Context.Set<Database.Service>().AsNoTracking().FirstOrDefault(s => s.ServiceId == sid);
                if (svc == null)
                    throw new UserException("Invalid service selected.");
                if (svc.Price.HasValue)
                    servicesTotal += svc.Price.Value;
            }

            return baseTotal + servicesTotal;
        }

        private static int GetBookingDurationDays(DateTime start, DateTime end)
        {
            var raw = (int)Math.Floor((end - start).TotalDays);
            return Math.Max(1, Math.Min(365, raw));
        }

        public Model.Reservation Cancel(int id)
        {
            var set = Context.Set<Database.Reservation>();
            var entity = set.Find(id);
            if (entity == null)
                throw new KeyNotFoundException($"Reservation with id {id} not found.");
            entity.Status = "Cancelled";
            Context.SaveChanges();
            return Mapper.Map<Model.Reservation>(entity);
        }

        public Model.Reservation Confirm(int id)
        {
            var set = Context.Set<Database.Reservation>();
            var entity = set.Find(id);
            if (entity == null)
                throw new KeyNotFoundException($"Reservation with id {id} not found.");
            if (string.Equals(entity.Status, "Cancelled", StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Cannot confirm a cancelled reservation.");
            entity.Status = "Confirmed";
            Context.SaveChanges();
            return Mapper.Map<Model.Reservation>(entity);
        }

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
    }
}
