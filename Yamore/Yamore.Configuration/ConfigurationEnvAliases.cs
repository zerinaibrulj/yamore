namespace Yamore.Configuration;

/// <summary>
/// Maps Docker-style environment names (<c>STRIPE_SECRET_KEY</c>, <c>SMTP_HOST</c>, …) to nested keys
/// (<c>Stripe__SecretKey</c>, <c>Smtp__Host</c>) expected by ASP.NET Core and the Worker host.
/// </summary>
public static class ConfigurationEnvAliases
{
    public static void Apply()
    {
        ApplyStripeKeyFromSource("Stripe__SecretKey", "STRIPE_SECRET_KEY", "sk_");
        ApplyStripeKeyFromSource("Stripe__PublishableKey", "STRIPE_PUBLISHABLE_KEY", "pk_");
        ApplyStripeKeyFromSource("Stripe__WebhookSecret", "STRIPE_WEBHOOK_SECRET", "whsec_");

        CopyIfTargetEmpty("Smtp__Host", "SMTP_HOST");
        CopyIfTargetEmpty("Smtp__Port", "SMTP_PORT");
        CopyIfTargetEmpty("Smtp__UserName", "SMTP_USER_NAME");
        CopyIfTargetEmpty("Smtp__Password", "SMTP_PASSWORD");
        CopyIfTargetEmpty("Smtp__UseSsl", "SMTP_USE_SSL");
        CopyIfTargetEmpty("Smtp__FromAddress", "SMTP_FROM_ADDRESS");
        CopyIfTargetEmpty("Smtp__FromDisplayName", "SMTP_FROM_DISPLAY_NAME");

        CopyIfTargetEmpty("DemoSeed__NotificationEmail", "DEMO_NOTIFICATION_EMAIL");
        CopyIfTargetEmpty("Jwt__Secret", "JWT_SECRET");
        CopyIfTargetEmpty("Jwt__Issuer", "JWT_ISSUER");
        CopyIfTargetEmpty("Jwt__Audience", "JWT_AUDIENCE");
    }

    private static void ApplyStripeKeyFromSource(string target, string source, string expectedPrefix)
    {
        var s = Environment.GetEnvironmentVariable(source);
        s = s?.Trim().TrimStart('\uFEFF');
        if (string.IsNullOrEmpty(s) || !s.StartsWith(expectedPrefix, StringComparison.Ordinal))
            return;

        var t = Environment.GetEnvironmentVariable(target);
        t = t?.Trim().TrimStart('\uFEFF');
        if (string.IsNullOrWhiteSpace(t) || !t.StartsWith(expectedPrefix, StringComparison.Ordinal))
            Environment.SetEnvironmentVariable(target, s);
    }

    private static void CopyIfTargetEmpty(string target, string source)
    {
        if (!string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable(target)))
            return;
        var value = Environment.GetEnvironmentVariable(source);
        if (!string.IsNullOrEmpty(value))
            Environment.SetEnvironmentVariable(target, value);
    }
}
