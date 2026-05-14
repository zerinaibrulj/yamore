using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.UserRole;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class UserRoleController : BaseCRUDController<Model.UserRole, UserRoleSearchObject, UserRoleInsertRequest, UserRoleUpdateRequest, UserRoleDeleteRequest>
    {
        public UserRoleController(IUserRoleService service) 
            : base(service)
        {
        }

        [HttpPost]
        [Authorize(Roles = AppRoles.Admin)]
        public override ActionResult<Model.UserRole> Insert(UserRoleInsertRequest request) => base.Insert(request);

        [HttpPut("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public override ActionResult<Model.UserRole> Update(int id, UserRoleUpdateRequest request) => base.Update(id, request);

        [HttpDelete("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public override ActionResult<Model.UserRole> Delete(int id) => base.Delete(id);
    }
}
