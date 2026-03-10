using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.SearchObjects
{
    public class UsersSearchObject : BaseSearchObject
    {
        public string? FirstNameGTE { get; set; }
        public string? LastNameGTE { get; set; }
        public string? Email { get; set; }
        public string? Username { get; set; }

        /// <summary>
        /// If true, include UserRoles and Role navigation when querying.
        /// </summary>
        public bool? IsUserRoleIncluded { get; set; }

        /// <summary>
        /// Optional role name to filter by (e.g. \"User\", \"YachtOwner\", \"Admin\").
        /// </summary>
        public string? RoleName { get; set; }

        /// <summary>
        /// Filter by active/suspended status. true = active only, false = suspended only, null = all.
        /// </summary>
        public bool? Status { get; set; }

        public string? OrderBy { get; set; }
    }
}
