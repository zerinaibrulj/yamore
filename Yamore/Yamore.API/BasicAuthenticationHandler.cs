using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;
using System.Net.Http.Headers;
using System.Security.Claims;
using System.Text;
using System.Text.Encodings.Web;
using Yamore.Services.Interfaces;

namespace Yamore.API
{
    public class BasicAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
    {
        IUsersService UserService;

        public BasicAuthenticationHandler(IOptionsMonitor<AuthenticationSchemeOptions> options, ILoggerFactory logger, UrlEncoder encoder, ISystemClock clock, IUsersService userService) 
            : base(options, logger, encoder, clock)
        {
            UserService = userService;
        }

        protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
        {
            if (!Request.Headers.TryGetValue("Authorization", out var authHeaderValue) || string.IsNullOrWhiteSpace(authHeaderValue))
            {
                return AuthenticateResult.Fail("Missing header");
            }

            if (!AuthenticationHeaderValue.TryParse(authHeaderValue, out var authHeader)
                || !"Basic".Equals(authHeader.Scheme, StringComparison.OrdinalIgnoreCase)
                || string.IsNullOrEmpty(authHeader.Parameter))
            {
                return AuthenticateResult.Fail("Invalid authorization header");
            }

            string username;
            string password;
            try
            {
                var credentialBytes = Convert.FromBase64String(authHeader.Parameter);
                var credentials = Encoding.UTF8.GetString(credentialBytes);
                // Password may contain ':'; only split on the first colon.
                var i = credentials.IndexOf(':');
                if (i <= 0)
                    return AuthenticateResult.Fail("Invalid credentials format");

                username = credentials[..i];
                password = credentials[(i + 1)..];
            }
            catch (FormatException)
            {
                return AuthenticateResult.Fail("Invalid base64");
            }

            if (string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password))
                return AuthenticateResult.Fail("Empty username or password");

            var user = UserService.Login(username, password);

            if(user == null)
            {
                return AuthenticateResult.Fail("Auth failed");
            }
            else
            {
                var claims = new List<Claim>()
                {
                    new Claim(ClaimTypes.Name, user.Username),
                    new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
                    new Claim("username", user.Username)
                };


                foreach(var role in user.Roles)
                {
                    claims.Add(new Claim(ClaimTypes.Role, role));     //Name se mora slagati sa onim koji se nalazi u Controlleru, odnosno [Authorize(Roles = "Admin")]
                }



                var identity = new ClaimsIdentity(claims, Scheme.Name);
                var principal = new ClaimsPrincipal(identity);
                var ticket = new AuthenticationTicket(principal, Scheme.Name);


                return AuthenticateResult.Success(ticket);
            }
        }
    }
}
