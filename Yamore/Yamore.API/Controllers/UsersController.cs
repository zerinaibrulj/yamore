using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;
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
        public PagedResult<Model.User> GetList([FromQuery]UsersSearchObject searchObject)
        {
            return _service.GetList(searchObject);
        }


        [HttpPost]
        public User Insert(UserInsertRequest request)
        {
            return _service.Insert(request);
        }


        [HttpPut("{id}")]
        public User Update(int id, UserUpdateRequest request)
        {
            return _service.Update(id, request);
        }
    }
}
