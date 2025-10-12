using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.Roles;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface IRoleService : ICRUDService<Model.Role, RoleSearchObject, RoleInsertRequest, RoleUpdateRequest, RoleDeleteRequest>
    {

    }
}
