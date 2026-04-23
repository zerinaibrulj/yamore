namespace Yamore.API.Configuration;

/// <summary>
/// Resolves Stripe keys from <c>IConfiguration</c> and process environment, even when
/// the nested <c>Stripe:SecretKey</c> name is not populated (e.g. only <c>STRIPE_SECRET_KEY</c> is set).
/// Trims and strips a UTF-8 BOM that sometimes appears in <c>.env</c> files.
/// Process environment and configuration candidates are resolved once per process (first call).
/// </summary>
public static class StripeKeyResolver
{
    private static readonly object Sync = new();
    private static bool _loaded;
    private static string? _secretKey;
    private static string? _publishableKey;

    public static string? GetSecretKey(IConfiguration configuration)
    {
        EnsureLoaded(configuration);
        return _secretKey;
    }

    public static string? GetPublishableKey(IConfiguration configuration)
    {
        EnsureLoaded(configuration);
        return _publishableKey;
    }

    private static void EnsureLoaded(IConfiguration configuration)
    {
        if (_loaded)
            return;
        lock (Sync)
        {
            if (_loaded)
                return;
            _secretKey = PickStripeKey(
                "sk_",
                Environment.GetEnvironmentVariable("STRIPE_SECRET_KEY"),
                configuration["STRIPE_SECRET_KEY"],
                configuration["Stripe:SecretKey"]);
            _publishableKey = PickStripeKey(
                "pk_",
                Environment.GetEnvironmentVariable("STRIPE_PUBLISHABLE_KEY"),
                configuration["STRIPE_PUBLISHABLE_KEY"],
                configuration["Stripe:PublishableKey"]);
            _loaded = true;
        }
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
        value = value.Replace("\r", string.Empty, StringComparison.Ordinal);
        if (string.IsNullOrEmpty(value))
            return null;
        return value;
    }

    private static bool IsPrefixed(string? s, string prefix) =>
        !string.IsNullOrEmpty(s) && s.StartsWith(prefix, StringComparison.Ordinal);
}
