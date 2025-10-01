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
    }
}
