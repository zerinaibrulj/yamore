using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.SearchObjects
{
    public class UserRoleSearchObject : BaseSearchObject
    {
        public int UserId { get; set; } 
        public int RoleId { get; set; }
    }
}
