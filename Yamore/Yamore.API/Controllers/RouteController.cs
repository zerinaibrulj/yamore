using Microsoft.AspNetCore.Mvc;
using Yamore.Model.Requests.Route;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class RouteController : BaseCRUDController<Model.Route, RouteSearchObject, RouteInsertRequest, RouteUpdateRequest, RouteDeleteRequest>
    {
        public RouteController(IRouteService service) 
            : base(service)
        {
        }
    }
}
