using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using Yamore.Model;

namespace Yamore.API.Auth;

public class JwtTokenIssuer
{
    private readonly JwtOptions _o;

    public JwtTokenIssuer(IOptions<JwtOptions> options) => _o = options.Value;

    public (string AccessToken, string Jti, int ExpiresInSeconds) CreateAccess(LoginResponseDto u)
    {
        var jti = Guid.NewGuid().ToString("N");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_o.Secret));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var minutes = _o.AccessTokenMinutes;
        if (minutes < 1) minutes = 5;
        var exp = DateTime.UtcNow.AddMinutes(minutes);
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, u.UserId.ToString(), ClaimValueTypes.String),
            new(ClaimTypes.Name, u.Username, ClaimValueTypes.String),
        };
        foreach (var r in u.Roles.Where(x => !string.IsNullOrWhiteSpace(x)))
            claims.Add(new Claim(ClaimTypes.Role, r, ClaimValueTypes.String));

        claims.Add(new(JwtRegisteredClaimNames.Jti, jti, ClaimValueTypes.String));

        var token = new JwtSecurityToken(
            _o.Issuer,
            _o.Audience,
            claims,
            expires: exp,
            signingCredentials: creds);

        var s = new JwtSecurityTokenHandler().WriteToken(token);
        return (s, jti, (int)TimeSpan.FromMinutes(minutes).TotalSeconds);
    }
}
