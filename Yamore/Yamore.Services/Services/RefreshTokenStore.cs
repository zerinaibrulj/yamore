using System;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Yamore.Services.Database;

namespace Yamore.Services.Services;

public interface IRefreshTokenStore
{
    /// <summary>Creates a new opaque token; returns raw (client) value and the persisted row id.</summary>
    (string rawToken, int id) Create(int userId, TimeSpan lifetime, DateTime utcNow);
    int? GetValidUserIdIfActive(string? rawToken, DateTime utcNow);
    void Revoke(int id);
    void RevokeByRaw(string? rawToken, DateTime utcNow);
    void RevokeAllForUser(int userId, DateTime utcNow);
}

public class RefreshTokenStore : IRefreshTokenStore
{
    private readonly _220245Context _db;

    public RefreshTokenStore(_220245Context db) => _db = db;

    public (string rawToken, int id) Create(int userId, TimeSpan lifetime, DateTime utcNow)
    {
        var buf = new byte[32];
        RandomNumberGenerator.Fill(buf);
        var raw = ToBase64Url(buf);
        var hash = Sha256Hex(raw);
        var entity = new RefreshToken
        {
            UserId = userId,
            TokenHash = hash,
            ExpiresUtc = utcNow.Add(lifetime),
            CreatedUtc = utcNow,
            Revoked = false,
        };
        _db.RefreshTokens.Add(entity);
        _db.SaveChanges();
        return (raw, entity.Id);
    }

    public int? GetValidUserIdIfActive(string? rawToken, DateTime utcNow)
    {
        if (string.IsNullOrWhiteSpace(rawToken))
            return null;
        var hash = Sha256Hex(rawToken!);
        var t = _db.RefreshTokens
            .AsNoTracking()
            .FirstOrDefault(x => x.TokenHash == hash && !x.Revoked && x.ExpiresUtc > utcNow);
        return t?.UserId;
    }

    public void Revoke(int id)
    {
        var t = _db.RefreshTokens.Find(id);
        if (t != null) t.Revoked = true;
        _db.SaveChanges();
    }

    public void RevokeByRaw(string? rawToken, DateTime utcNow)
    {
        if (string.IsNullOrWhiteSpace(rawToken)) return;
        var hash = Sha256Hex(rawToken!);
        var t = _db.RefreshTokens
            .FirstOrDefault(x => x.TokenHash == hash && !x.Revoked && x.ExpiresUtc > utcNow);
        if (t != null) t.Revoked = true;
        _db.SaveChanges();
    }

    public void RevokeAllForUser(int userId, DateTime utcNow)
    {
        var list = _db.RefreshTokens
            .Where(x => x.UserId == userId && !x.Revoked && x.ExpiresUtc > utcNow);
        foreach (var x in list) x.Revoked = true;
        _db.SaveChanges();
    }

    private static string Sha256Hex(string s)
    {
        var b = SHA256.HashData(Encoding.UTF8.GetBytes(s));
        var sb = new StringBuilder(b.Length * 2);
        foreach (var x in b) sb.Append(x.ToString("x2"));
        return sb.ToString();
    }

    private static string ToBase64Url(byte[] data) =>
        Convert.ToBase64String(data).TrimEnd('=').Replace('+', '-').Replace('/', '_');
}
