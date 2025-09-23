using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.SearchObjects;
using Yamore.Services;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class YachtsController : ControllerBase
    {
        protected IYachtsService _service;

        public YachtsController(IYachtsService service) 
        {
            _service = service;
        }

        [HttpGet]
        public List<Yachts> GetList([FromQuery]YachtsSearchObject searchObject)
        {
            return _service.GetList(searchObject);
        }
    }
}
