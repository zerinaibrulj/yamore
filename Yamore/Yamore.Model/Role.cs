using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model
{
    public class Role
    {
        public int RoleId { get; set; }
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
        //public virtual ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
    }
}
