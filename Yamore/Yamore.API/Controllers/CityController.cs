using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.City;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class CityController : BaseCRUDController<Model.City, CitySearchObject, CityInsertRequest, CityUpdateRequest, CityDeleteRequest>
    {
        public CityController(ICityService service)
            : base(service)
        {
        }
    }
}
