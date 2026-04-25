using System;

namespace Yamore.Services.Security;

public static class UploadedImageGuard
{
    /// <summary>Magic-byte sniffing for common web image formats; extension-only checks are not sufficient.</summary>
    public static bool IsKnownImageFile(ReadOnlySpan<byte> data)
    {
        if (data.Length < 12) return false;
        // JPEG
        if (data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF)
        {
            return true;
        }

        // PNG
        if (data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47)
        {
            return true;
        }

        // GIF
        if (data[0] == (byte)'G' && data[1] == (byte)'I' && data[2] == (byte)'F' && data[3] == (byte)'8')
        {
            return true;
        }

        // RIFF (WebP container)
        if (data[0] == (byte)'R' && data[1] == (byte)'I' && data[2] == (byte)'F' && data[3] == (byte)'F' &&
            data[8] == (byte)'W' && data[9] == (byte)'E' && data[10] == (byte)'B' && data[11] == (byte)'P')
        {
            return true;
        }

        return false;
    }

    public static bool IsAllowedImageMimeType(string? contentType)
    {
        if (string.IsNullOrWhiteSpace(contentType))
        {
            return false;
        }

        var t = contentType.Split(';', 2, StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries)[0];
        return t.Equals("image/jpeg", StringComparison.OrdinalIgnoreCase)
            || t.Equals("image/pjpeg", StringComparison.OrdinalIgnoreCase)
            || t.Equals("image/png", StringComparison.OrdinalIgnoreCase)
            || t.Equals("image/gif", StringComparison.OrdinalIgnoreCase)
            || t.Equals("image/webp", StringComparison.OrdinalIgnoreCase);
    }
}
