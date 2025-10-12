using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.Roles;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class RoleService : BaseCRUDService<Model.Role, RoleSearchObject, Database.Role, RoleInsertRequest, RoleUpdateRequest, RoleDeleteRequest>, IRoleService
    {
        public RoleService(_220245Context context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override IQueryable<Database.Role> AddFilter(RoleSearchObject search, IQueryable<Database.Role> query)
        {
            var filteredQurey = base.AddFilter(search, query);

            if (!string.IsNullOrWhiteSpace(search?.NameGTE))
            {
                filteredQurey = filteredQurey.Where(x => x.Name.StartsWith(search.NameGTE));
            }
            return filteredQurey;
        }
    }
}
