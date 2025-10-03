using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.Route;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface IRouteService : ICRUDService<Model.Route, RouteSearchObject, RouteInsertRequest, RouteUpdateRequest, RouteDeleteRequest>
    {
    }
}
