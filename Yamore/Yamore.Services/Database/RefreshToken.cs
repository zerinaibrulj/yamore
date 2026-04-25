using System;

namespace Yamore.Services.Database;

/// <summary>
/// Opaque refresh token (hash stored, never the raw value).
/// </summary>
public partial class RefreshToken
{
    public int Id { get; set; }
    public int UserId { get; set; }
    /// <summary>SHA-256 (hex) of the opaque refresh token.</summary>
    public string TokenHash { get; set; } = null!;
    public DateTime ExpiresUtc { get; set; }
    public bool Revoked { get; set; }
    public DateTime CreatedUtc { get; set; }

    public virtual User? User { get; set; }
}
