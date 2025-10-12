using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.Requests.Roles
{
    public class RoleInsertRequest
    {
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
    }
}
