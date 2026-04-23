namespace Yamore.Worker;

/// <summary>See Yamore.API.Configuration.ConfigurationEnvAliases — same for Worker host.</summary>
public static class ConfigurationEnvAliases
{
    public static void Apply()
    {
        ApplyStripeKeyFromSource("Stripe__SecretKey", "STRIPE_SECRET_KEY", "sk_");
        ApplyStripeKeyFromSource("Stripe__PublishableKey", "STRIPE_PUBLISHABLE_KEY", "pk_");

        CopyIfTargetEmpty("Smtp__Host", "SMTP_HOST");
        CopyIfTargetEmpty("Smtp__Port", "SMTP_PORT");
        CopyIfTargetEmpty("Smtp__UserName", "SMTP_USER_NAME");
        CopyIfTargetEmpty("Smtp__Password", "SMTP_PASSWORD");
        CopyIfTargetEmpty("Smtp__UseSsl", "SMTP_USE_SSL");
        CopyIfTargetEmpty("Smtp__FromAddress", "SMTP_FROM_ADDRESS");
        CopyIfTargetEmpty("Smtp__FromDisplayName", "SMTP_FROM_DISPLAY_NAME");

        CopyIfTargetEmpty("DemoSeed__NotificationEmail", "DEMO_NOTIFICATION_EMAIL");
    }

    private static void ApplyStripeKeyFromSource(string target, string source, string expectedPrefix)
    {
        var s = System.Environment.GetEnvironmentVariable(source);
        s = s?.Trim().TrimStart('\uFEFF');
        if (string.IsNullOrEmpty(s) || !s.StartsWith(expectedPrefix, StringComparison.Ordinal))
            return;

        var t = System.Environment.GetEnvironmentVariable(target);
        t = t?.Trim().TrimStart('\uFEFF');
        if (string.IsNullOrWhiteSpace(t) || !t.StartsWith(expectedPrefix, StringComparison.Ordinal))
            System.Environment.SetEnvironmentVariable(target, s);
    }

    private static void CopyIfTargetEmpty(string target, string source)
    {
        if (!string.IsNullOrWhiteSpace(System.Environment.GetEnvironmentVariable(target)))
            return;
        var value = System.Environment.GetEnvironmentVariable(source);
        if (!string.IsNullOrEmpty(value))
            System.Environment.SetEnvironmentVariable(target, value);
    }
}
