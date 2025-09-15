using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Services;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class YachtsController : ControllerBase
    {
        protected IYachtsService _service;

        public YachtsController(YachtsService service) 
        {
            _service = service;
        }

        [HttpGet]
        public List<Yachts> GetList()
        {
            return _service.GetList();
        }
    }
}
