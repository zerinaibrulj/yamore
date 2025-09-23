using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model
{
    public class UserRole
    {
        public int UserRoleId { get; set; }
        public int UserId { get; set; }
        public int RoleId { get; set; }
        public DateTime DateModification { get; set; }
        //public virtual User User { get; set; } = null!;   //making circular reference
        public virtual Role Role { get; set; } = null!;
    }
}
