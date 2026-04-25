namespace Yamore.API.Auth;

public class JwtOptions
{
    public const string SectionName = "Jwt";
    public string Secret { get; set; } = null!;
    public string Issuer { get; set; } = "Yamore";
    public string Audience { get; set; } = "Yamore.Clients";
    public int AccessTokenMinutes { get; set; } = 60;
    public int RefreshTokenDays { get; set; } = 14;
}
