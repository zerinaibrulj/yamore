using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.UserRole;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class UserRoleService : BaseCRUDService<Model.UserRole, UserRoleSearchObject, Database.UserRole, UserRoleInsertRequest, UserRoleUpdateRequest, UserRoleDeleteRequest>, IUserRoleService
    {
        public UserRoleService(_220245Context context, IMapper mapper) 
            : base(context, mapper)
        {
        }
    }
}
