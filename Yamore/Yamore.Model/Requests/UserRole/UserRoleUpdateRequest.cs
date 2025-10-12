using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.Requests.UserRole
{
    public class UserRoleUpdateRequest
    {
        public int UserId { get; set; }
        public int RoleId { get; set; }
    }
}
