namespace Yamore.Model.Requests.User
{
    public class TokenRefreshRequest
    {
        public string? RefreshToken { get; set; }
    }

    public class LogoutRequest
    {
        public string? RefreshToken { get; set; }
    }
}
