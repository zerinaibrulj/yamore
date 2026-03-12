using MapsterMapper;
using Yamore.Model.Requests.YachtService;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class YachtServiceService : BaseCRUDService<Model.YachtService, YachtServiceSearchObject, Database.YachtService, YachtServiceInsertRequest, YachtServiceUpdateRequest, YachtServiceDeleteRequest>, IYachtServiceService
    {
        public YachtServiceService(_220245Context context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override IQueryable<Database.YachtService> AddFilter(YachtServiceSearchObject search, IQueryable<Database.YachtService> query)
        {
            var filtered = base.AddFilter(search, query);

            if (search?.YachtServiceId != null)
                filtered = filtered.Where(x => x.YachtServiceId == search.YachtServiceId);

            if (search?.YachtId != null)
                filtered = filtered.Where(x => x.YachtId == search.YachtId);

            if (search?.ServiceId != null)
                filtered = filtered.Where(x => x.ServiceId == search.ServiceId);

            return filtered;
        }
    }
}
