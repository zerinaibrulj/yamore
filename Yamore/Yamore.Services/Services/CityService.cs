using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.Requests.City;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class CityService : BaseCRUDService<Model.City, CitySearchObject, Database.City, CityInsertRequest, CityUpdateRequest, CityDeleteRequest>, ICityService
    {
        private const string CityDeleteBlockedMessage =
            "This city cannot be deleted because it is still in use. "
            + "One or more yachts use it as their location. One or more routes start or end in this city. "
            + "Update those yachts and routes (or choose another city) before deleting.";

        public CityService(_220245Context context, IMapper mapper) 
            : base(context, mapper)
        {
        }

        /// <inheritdoc />
        public string? GetDeleteBlockingErrorMessage(int cityId)
        {
            var hasYachts = Context.Yachts.AsNoTracking().Any(y => y.LocationId == cityId);
            var hasRoutes = Context.Routes.AsNoTracking()
                .Any(r => r.StartCityId == cityId || r.EndCityId == cityId);
            if (!hasYachts && !hasRoutes) return null;
            return CityDeleteBlockedMessage;
        }

        public override Model.City Delete(int id)
        {
            // Safety net if Delete is called without the controller's non-throwing pre-check.
            var err = GetDeleteBlockingErrorMessage(id);
            if (err != null) throw new UserException(err);
            return base.Delete(id);
        }

        public override IQueryable<Database.City> AddFilter(CitySearchObject search, IQueryable<Database.City> query)
        {
            var filteredQurey = base.AddFilter(search, query);

            if (!string.IsNullOrWhiteSpace(search?.NameGTE))
            {
                filteredQurey = filteredQurey.Where(x => x.Name.StartsWith(search.NameGTE));
            }
            return filteredQurey;
        }
    }
}
