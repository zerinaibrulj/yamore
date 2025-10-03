using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.Route;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class RouteService : BaseCRUDService<Model.Route, RouteSearchObject, Database.Route, RouteInsertRequest, RouteUpdateRequest, RouteDeleteRequest>, IRouteService
    {
        public RouteService(_220245Context context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override IQueryable<Database.Route> AddFilter(RouteSearchObject search, IQueryable<Database.Route> query)
        {
            var filteredQurey = base.AddFilter(search, query);

            if (search?.StartCityId != null)
            {
                filteredQurey = filteredQurey.Where(x => x.StartCityId == search.StartCityId);
            }

            if (search?.EndCityId != null)
            {
                filteredQurey = filteredQurey.Where(x => x.EndCityId == search.EndCityId);
            }

            if (search?.EstimatedDurationHours != null)
            {
                filteredQurey = filteredQurey.Where(x => x.EstimatedDurationHours == search.EstimatedDurationHours);
            }


            return filteredQurey;
        }
    }
}
