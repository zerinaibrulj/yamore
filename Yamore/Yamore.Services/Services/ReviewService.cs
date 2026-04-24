using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.Requests.Review;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class ReviewService : BaseCRUDService<Model.Review, ReviewSearchObject, Database.Review, ReviewInsertRequest, ReviewUpdateRequest, ReviewDeleteRequest>, IReviewService
    {
        public ReviewService(_220245Context context, IMapper mapper) 
            : base(context, mapper)
        {
        }

        public override Model.Review Insert(ReviewInsertRequest request)
        {
            var reservation = Context.Set<Database.Reservation>().Find(request.ReservationId);
            if (reservation == null)
                throw new NotFoundException($"Reservation with id {request.ReservationId} not found.");
            if (!string.Equals(reservation.Status, ReservationStatuses.Completed, StringComparison.OrdinalIgnoreCase))
                throw new UserException("You can only leave a review after the trip is completed.");

            return base.Insert(request);
        }

        public override IQueryable<Database.Review> AddFilter(ReviewSearchObject search, IQueryable<Database.Review> query)
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

            if (search?.Rating != null)
            {
                filteredQurey = filteredQurey.Where(x => x.Rating == search.Rating);
            }

            if (search?.IsReported != null)
            {
                filteredQurey = filteredQurey.Where(x => x.IsReported == search.IsReported);
            }

            return filteredQurey;
        }

        public Model.Review Report(int id)
        {
            var entity = Context.Reviews.Find(id);
            if (entity == null)
                throw new NotFoundException($"Review with id {id} not found.");
            entity.IsReported = true;
            Context.SaveChanges();
            return Mapper.Map<Model.Review>(entity);
        }

        public Model.Review Unreport(int id)
        {
            var entity = Context.Reviews.Find(id);
            if (entity == null)
                throw new NotFoundException($"Review with id {id} not found.");
            entity.IsReported = false;
            Context.SaveChanges();
            return Mapper.Map<Model.Review>(entity);
        }

        public Model.Review RespondAsOwner(int id, string ownerResponse)
        {
            var entity = Context.Reviews.Find(id);
            if (entity == null)
                throw new NotFoundException($"Review with id {id} not found.");
            entity.OwnerResponse = ownerResponse;
            entity.OwnerResponseDate = DateTime.UtcNow;
            Context.SaveChanges();
            return Mapper.Map<Model.Review>(entity);
        }
    }
}
