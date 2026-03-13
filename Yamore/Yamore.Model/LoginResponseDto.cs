using System.Collections.Generic;

namespace Yamore.Model
{
    /// <summary>Login response with no circular references, safe for JSON serialization.</summary>
    public class LoginResponseDto
    {
        public int UserId { get; set; }
        public string FirstName { get; set; } = null!;
        public string LastName { get; set; } = null!;
        public string? Email { get; set; }
        public string? Phone { get; set; }
        public string Username { get; set; } = null!;
        public bool? Status { get; set; }
        public List<string> Roles { get; set; } = new List<string>();
    }
}
