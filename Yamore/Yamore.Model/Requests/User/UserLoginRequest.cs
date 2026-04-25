namespace Yamore.Model.Requests.User
{
    /// <summary>JSON body for <c>POST /Users/login</c> (credentials must not be sent in the query string).</summary>
    public class UserLoginRequest
    {
        public string? Username { get; set; }
        public string? Password { get; set; }
    }
}
