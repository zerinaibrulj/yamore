using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.Requests
{
    public class UserInsertRequest
    {
        public string FirstName { get; set; } = null!;

        public string LastName { get; set; } = null!;

        public string? Email { get; set; }

        public string? Phone { get; set; }
        public string Password { get; set; } 
        public string PasswordConfirmation { get; set; }
        //public string Username { get; set; } = null!;   //dodat cemo ova 2 propertija kasnije
        //public bool? Status { get; set; }
    }
}
