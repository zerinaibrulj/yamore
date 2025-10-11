using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.User;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class UsersController : BaseCRUDController<Model.User, UsersSearchObject, UserInsertRequest, UserUpdateRequest, UserDeleteRequest>
    {
        public UsersController(IUsersService service)
            : base(service)
        {
        }


        [HttpPost("login")]
        [AllowAnonymous]
        public Model.User Login(string username, string password)
        {
            return (_service as IUsersService).Login(username, password);
        }
    }
}
