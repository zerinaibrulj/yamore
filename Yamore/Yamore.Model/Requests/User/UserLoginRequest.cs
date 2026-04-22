namespace Yamore.Model.Requests.User
{
    /// <summary>JSON body for <c>POST /Users/login</c> (query string is also supported).</summary>
    public class UserLoginRequest
    {
        public string? Username { get; set; }
        public string? Password { get; set; }
    }
}
