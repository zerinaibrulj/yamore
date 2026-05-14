using System;
using System.Linq;
using System.Security.Claims;
using MapsterMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Yamore.Model;
using Yamore.Model.Requests.Review;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class ReviewService : BaseCRUDService<Model.Review, ReviewSearchObject, Database.Review, ReviewInsertRequest, ReviewUpdateRequest, ReviewDeleteRequest>, IReviewService
    {
        private readonly IHttpContextAccessor? _httpContextAccessor;

        public ReviewService(
            _220245Context context,
            IMapper mapper,
            IHttpContextAccessor? httpContextAccessor = null)
            : base(context, mapper)
        {
            _httpContextAccessor = httpContextAccessor;
        }

        public override Model.Review Insert(ReviewInsertRequest request)
        {
            var http = _httpContextAccessor?.HttpContext;
            if (!int.TryParse(http?.User?.FindFirstValue(ClaimTypes.NameIdentifier), out var bookerId))
                throw new ForbiddenException("You must be signed in to submit a review.");

            var reservation = Context.Set<Database.Reservation>()
                .AsNoTracking()
                .FirstOrDefault(r => r.ReservationId == request.ReservationId);
            if (reservation == null)
                throw new NotFoundException($"Reservation with id {request.ReservationId} not found.");

            if (reservation.UserId != bookerId)
                throw new ForbiddenException("You may only review your own completed reservations.");

            if (reservation.YachtId != request.YachtId)
                throw new UserException("The selected yacht does not match this reservation.");

            if (!string.Equals(reservation.Status, ReservationStatuses.Completed, StringComparison.OrdinalIgnoreCase))
                throw new UserException("You can only leave a review after the trip is completed.");

            if (Context.Set<Database.Review>().AsNoTracking().Any(x => x.ReservationId == request.ReservationId))
                throw new UserException("A review has already been submitted for this reservation.");

            var entity = new Database.Review
            {
                ReservationId = request.ReservationId,
                UserId = bookerId,
                YachtId = request.YachtId,
                Rating = request.Rating,
                Comment = request.Comment,
                DatePosted = DateTime.UtcNow,
                IsReported = false,
            };

            Context.Add(entity);
            Context.SaveChanges();
            return Mapper.Map<Model.Review>(entity);
        }

        public override Model.Review Update(int id, ReviewUpdateRequest request)
        {
            var http = _httpContextAccessor?.HttpContext;
            if (!int.TryParse(http?.User?.FindFirstValue(ClaimTypes.NameIdentifier), out var uid))
                throw new ForbiddenException("You must be signed in to update a review.");

            var entity = Context.Set<Database.Review>().Find(id);
            if (entity == null)
                throw new NotFoundException($"Review with id {id} not found.");

            if (entity.UserId != uid)
                throw new ForbiddenException("You may only edit your own reviews.");

            if (request.ReservationId != entity.ReservationId || request.YachtId != entity.YachtId)
                throw new UserException("Reservation and yacht cannot be changed for an existing review.");

            entity.Rating = request.Rating;
            entity.Comment = request.Comment;
            Context.SaveChanges();
            return Mapper.Map<Model.Review>(entity);
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
            var entity = Context.Set<Database.Review>()
                .Include(r => r.Yacht)
                .FirstOrDefault(r => r.ReviewId == id);
            if (entity == null)
                throw new NotFoundException($"Review with id {id} not found.");

            var http = _httpContextAccessor?.HttpContext;
            if (!int.TryParse(http?.User?.FindFirstValue(ClaimTypes.NameIdentifier), out var uid))
                throw new ForbiddenException("You must be signed in to respond to a review.");

            var isAdmin = http.User.IsInRole(AppRoles.Admin);
            if (!isAdmin && entity.Yacht.OwnerId != uid)
            {
                throw new ForbiddenException(
                    "Only the owner of the yacht that was reviewed may post an owner response.");
            }

            var text = (ownerResponse ?? string.Empty).Trim();
            entity.OwnerResponse = string.IsNullOrEmpty(text) ? null : text;
            entity.OwnerResponseDate = DateTime.UtcNow;
            Context.SaveChanges();
            return Mapper.Map<Model.Review>(entity);
        }
    }
}
