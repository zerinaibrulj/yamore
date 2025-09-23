using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Yamore.Services.Database
{
    public class UserRole
    {
        public int UserRoleId { get; set; }
        public int UserId { get; set; }
        public int RoleId { get; set; }
        public DateTime DateModification { get; set; }
        public virtual User User { get; set; } = null!;
        public virtual Role Role { get; set; } = null!;
    }
}
