using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.Requests.User
{
    public class UserInsertRequest
    {
        public string FirstName { get; set; } = null!;

        public string LastName { get; set; } = null!;

        public string? Email { get; set; }

        public string? Phone { get; set; }
        public string Username { get; set; } = null!;
        public string Password { get; set; } 
        public string PasswordConfirmation { get; set; }  
        public bool? Status { get; set; }
        /// <summary>Used when an administrator creates a user. The public <c>POST Users/register</c> endpoint ignores this
        /// (and <see cref="Status" />) so clients cannot self-assign roles.</summary>
        public string? RoleName { get; set; }
    }
}
