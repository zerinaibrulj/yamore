using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.City;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface ICityService : ICRUDService<Model.City, CitySearchObject, CityInsertRequest, CityUpdateRequest, CityDeleteRequest>
    {
        /// <summary>If this city can be deleted, returns <c>null</c>; otherwise the message to return to the client (HTTP 400).</summary>
        string? GetDeleteBlockingErrorMessage(int cityId);
    }
}
