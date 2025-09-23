using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.SearchObjects
{
    public class UsersSearchObject
    {
        public string? FirstNameGTE { get; set; }
        public string? LastNameGTE { get; set; }
        public string? Email { get; set; }
        public string? Username { get; set; }
        public bool? IsUserRoleIncluded { get; set; }
    }
}
