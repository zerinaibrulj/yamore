using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.Country;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface ICountryService : ICRUDService<Model.Country, CountrySearchObject, CountryInsertRequest, CountryUpdateRequest, CountryDeleteRequest>
    {
        /// <summary>If this country can be deleted, returns <c>null</c>; otherwise the message to return to the client (HTTP 400).</summary>
        string? GetDeleteBlockingErrorMessage(int countryId);
    }
}
