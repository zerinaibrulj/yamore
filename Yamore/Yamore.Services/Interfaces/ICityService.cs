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
    }
}
