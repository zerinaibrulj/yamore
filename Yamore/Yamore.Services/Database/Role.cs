using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Yamore.Services.Database
{
    public class Role
    {
        public int RoleId { get; set; }
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
        //public virtual ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
    }
}
