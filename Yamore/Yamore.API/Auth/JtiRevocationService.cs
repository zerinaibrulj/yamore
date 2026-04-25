using Microsoft.Extensions.Caching.Memory;

namespace Yamore.API.Auth;

/// <summary>Server-side invalidation for access token JTIs (logout) until the token would have expired.</summary>
public interface IJtiRevocationService
{
    void Revoke(string jti, DateTimeOffset accessTokenExpires);
    bool IsRevoked(string? jti);
}

public class JtiRevocationService : IJtiRevocationService
{
    private readonly IMemoryCache _cache;

    public JtiRevocationService(IMemoryCache cache) => _cache = cache;

    public void Revoke(string jti, DateTimeOffset accessTokenExpires)
    {
        if (string.IsNullOrEmpty(jti)) return;
        if (accessTokenExpires <= DateTimeOffset.UtcNow) return;
        _cache.Set("jti:" + jti, 1, accessTokenExpires);
    }

    public bool IsRevoked(string? jti) =>
        !string.IsNullOrEmpty(jti) && _cache.TryGetValue("jti:" + jti, out _);
}
