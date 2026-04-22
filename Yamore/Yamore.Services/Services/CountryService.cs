using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.Requests.Country;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class CountryService : BaseCRUDService<Model.Country, CountrySearchObject, Database.Country, CountryInsertRequest, CountryUpdateRequest, CountryDeleteRequest>, ICountryService
    {
        private const string CountryDeleteBlockedMessage =
            "This country cannot be deleted because it is still in use. "
            + "One or more cities are associated with this country. "
            + "Remove or reassign those cities to another country before deleting.";

        public CountryService(_220245Context context, IMapper mapper) 
            : base(context, mapper)
        {
        }

        /// <inheritdoc />
        public string? GetDeleteBlockingErrorMessage(int countryId)
        {
            if (!Context.Cities.AsNoTracking().Any(c => c.CountryId == countryId)) return null;
            return CountryDeleteBlockedMessage;
        }

        public override Model.Country Delete(int id)
        {
            var err = GetDeleteBlockingErrorMessage(id);
            if (err != null) throw new UserException(err);
            return base.Delete(id);
        }

        public override IQueryable<Database.Country> AddFilter(CountrySearchObject search, IQueryable<Database.Country> query)
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
