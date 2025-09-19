using System;

namespace Yamore.Model
{
    public class User
    {
        public int UserId { get; set; }

        public string FirstName { get; set; } = null!;

        public string LastName { get; set; } = null!;

        public string? Email { get; set; }

        public string? Phone { get; set; }
        public string Username { get; set; } = null!;   
        public bool? Status { get; set; }
    }
}
