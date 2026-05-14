using Microsoft.AspNetCore.Authorization;
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
        public RoleController(IRoleService service) 
            : base(service)
        {
        }

        [HttpPost]
        [Authorize(Roles = AppRoles.Admin)]
        public override ActionResult<Model.Role> Insert(RoleInsertRequest request) => base.Insert(request);

        [HttpPut("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public override ActionResult<Model.Role> Update(int id, RoleUpdateRequest request) => base.Update(id, request);

        [HttpDelete("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public override ActionResult<Model.Role> Delete(int id) => base.Delete(id);
    }
}
