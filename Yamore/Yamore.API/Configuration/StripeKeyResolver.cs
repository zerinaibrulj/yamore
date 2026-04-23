namespace Yamore.API.Configuration;

/// <summary>
/// Resolves Stripe keys from <c>IConfiguration</c> and process environment, even when
/// the nested <c>Stripe:SecretKey</c> name is not populated (e.g. only <c>STRIPE_SECRET_KEY</c> is set).
/// Trims and strips a UTF-8 BOM that sometimes appears in <c>.env</c> files.
/// </summary>
public static class StripeKeyResolver
{
    public static string? GetSecretKey(IConfiguration configuration)
    {
        // Order: process env (set by .env) → flat config (also maps STRIPE_SECRET_KEY from env provider)
        // → nested Stripe:SecretKey (e.g. User Secrets / appsettings)
        return PickStripeKey(
            "sk_",
            Environment.GetEnvironmentVariable("STRIPE_SECRET_KEY"),
            configuration["STRIPE_SECRET_KEY"],
            configuration["Stripe:SecretKey"]);
    }

    public static string? GetPublishableKey(IConfiguration configuration)
    {
        return PickStripeKey(
            "pk_",
            Environment.GetEnvironmentVariable("STRIPE_PUBLISHABLE_KEY"),
            configuration["STRIPE_PUBLISHABLE_KEY"],
            configuration["Stripe:PublishableKey"]);
    }

    private static string? PickStripeKey(string prefix, params string?[] candidates)
    {
        for (var i = 0; i < candidates.Length; i++)
        {
            var c = Normalize(candidates[i]);
            if (IsPrefixed(c, prefix))
                return c;
        }
        for (var i = 0; i < candidates.Length; i++)
        {
            var c = Normalize(candidates[i]);
            if (!string.IsNullOrEmpty(c))
                return c;
        }
        return null;
    }

    private static string? Normalize(string? value)
    {
        if (string.IsNullOrEmpty(value))
            return null;
        value = value.Trim().TrimStart('\uFEFF');
        if (value.Length >= 2)
        {
            if (value[0] == '\'' && value[^1] == '\'')
                value = value[1..^1].Trim();
            else if (value[0] == '"' && value[^1] == '"')
                value = value[1..^1].Trim();
        }
        // Strip stray \r in case of line folding in .env
        value = value.Replace("\r", string.Empty, StringComparison.Ordinal);
        if (string.IsNullOrEmpty(value))
            return null;
        return value;
    }

    private static bool IsPrefixed(string? s, string prefix) =>
        !string.IsNullOrEmpty(s) && s.StartsWith(prefix, StringComparison.Ordinal);
}
