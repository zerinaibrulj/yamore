using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
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

            return filteredQurey;
        }

    }
}
