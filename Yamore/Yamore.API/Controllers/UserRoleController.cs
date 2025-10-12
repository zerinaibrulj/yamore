using Yamore.Model;
using Yamore.Model.Requests.UserRole;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    public class UserRoleController : BaseCRUDController<Model.UserRole, UserRoleSearchObject, UserRoleInsertRequest, UserRoleUpdateRequest, UserRoleDeleteRequest>
    {
        public UserRoleController(IUserRoleService service) 
            : base(service)
        {
        }
    }
}
