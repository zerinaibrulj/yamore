using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Services;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class UsersController : ControllerBase
    {
        protected IUsersService _service;

        public UsersController(IUsersService service) 
        {
            _service = service;
        }

        [HttpGet]
        public List<Model.User> GetList()
        {
            return _service.GetList();
        }
    }
}
