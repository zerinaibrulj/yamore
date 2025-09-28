using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;
using Yamore.Services;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class UsersController : BaseCRUDController<User, UsersSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        public UsersController(IUsersService service)
            : base(service)
        {

        }
    }
}
