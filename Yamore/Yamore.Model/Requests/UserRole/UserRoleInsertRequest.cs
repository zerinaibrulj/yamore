using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.Requests.UserRole
{
    public class UserRoleInsertRequest
    {
        public int UserId { get; set; }
        public int RoleId { get; set; }
    }
}
