using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.UserRole;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface IUserRoleService : ICRUDService<Model.UserRole, UserRoleSearchObject, UserRoleInsertRequest, UserRoleUpdateRequest, UserRoleDeleteRequest>
    {
    }
}
