using MapsterMapper;
using Microsoft.EntityFrameworkCore;
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

        public override void BeforeInsret(UserRoleInsertRequest request, Database.UserRole entity)
        {
            entity.DateModification = DateTime.UtcNow;
            base.BeforeInsret(request, entity);
        }


        public override IQueryable<Database.UserRole> AddFilter(UserRoleSearchObject search, IQueryable<Database.UserRole> query)
        {
            var filteredQuery = base.AddFilter(search, query);

            if (search.UserId != null && search.UserId != 0)
            {
                filteredQuery = filteredQuery.Where(x => x.UserId == search.UserId);
            }

            if (search.RoleId != null && search.RoleId != 0)
            {
                filteredQuery = filteredQuery.Where(x => x.RoleId == search.RoleId);
            }

            return filteredQuery;
        }
    }
}
