using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.Requests.User
{
    public class UserUpdateRequest
    {
        public string FirstName { get; set; } = null!;

        public string LastName { get; set; } = null!;

        public string? Phone { get; set; }

        /// <summary>
        /// Required only when a user changes their own password.
        /// Administrators can change other users' passwords without providing the old password.
        /// </summary>
        public string? OldPassword { get; set; }
        public string? Password { get; set; }
        public string? PasswordConfirmation { get; set; }
        public bool? Status { get; set; }
    }
}
