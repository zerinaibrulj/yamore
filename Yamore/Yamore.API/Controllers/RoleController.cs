using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.Roles;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class RoleController : BaseCRUDController<Model.Role, RoleSearchObject, RoleInsertRequest, RoleUpdateRequest, RoleDeleteRequest>
    {
        public RoleController(ICRUDService<Role, RoleSearchObject, RoleInsertRequest, RoleUpdateRequest, RoleDeleteRequest> service) 
            : base(service)
        {
        }
    }
}
