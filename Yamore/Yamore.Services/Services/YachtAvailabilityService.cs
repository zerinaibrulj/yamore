using System.Linq;
using MapsterMapper;
using Yamore.Model.Requests.YachtAvailability;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class YachtAvailabilityService : BaseCRUDService<Model.YachtAvailability, YachtAvailabilitySearchObject, Database.YachtAvailability, YachtAvailabilityInsertRequest, YachtAvailabilityUpdateRequest, YachtAvailabilityDeleteRequest>, IYachtAvailabilityService
    {
        public YachtAvailabilityService(_220245Context context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override IQueryable<Database.YachtAvailability> AddFilter(YachtAvailabilitySearchObject search, IQueryable<Database.YachtAvailability> query)
        {
            var filteredQuery = base.AddFilter(search, query);

            if (search?.YachtId != null)
                filteredQuery = filteredQuery.Where(x => x.YachtId == search.YachtId);

            if (search?.StartDateFrom != null)
                filteredQuery = filteredQuery.Where(x => x.EndDate >= search.StartDateFrom.Value);

            if (search?.EndDateTo != null)
                filteredQuery = filteredQuery.Where(x => x.StartDate <= search.EndDateTo.Value);

            if (search?.IsBlocked != null)
                filteredQuery = filteredQuery.Where(x => x.IsBlocked == search.IsBlocked);

            return filteredQuery;
        }
    }
}
