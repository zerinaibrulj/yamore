using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.Reservation;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class ReservationService : BaseCRUDService<Model.Reservation, ReservationSearchObject, Database.Reservation, ReservationInsertRequest, ReservationUpdateRequest, ReservationDeleteRequest>, IReservationService
    {
        public ReservationService(_220245Context context, IMapper mapper) 
            : base(context, mapper)
        {
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

            // Check for overlapping reservations for the same yacht (excluding cancelled)
            var overlapping = Context.Set<Database.Reservation>()
                .Where(r => r.YachtId == yachtId && r.Status != null && r.Status != "Cancelled")
                .Any(r => start < r.EndDate && end > r.StartDate);

            if (overlapping)
                throw new InvalidOperationException("This yacht is already reserved for the selected dates. Please choose different dates or times.");

            return base.Insert(request);
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
    }
}
