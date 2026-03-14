using Stripe;

namespace Yamore.API.Services;

/// <summary>
/// Handles Stripe PaymentIntent creation and verification for card payments.
/// Configure Stripe:SecretKey and Stripe:PublishableKey in appsettings or User Secrets.
/// </summary>
public class StripePaymentService
{
    private readonly string? _secretKey;
    private readonly StripeClient? _stripeClient;

    public StripePaymentService(IConfiguration configuration)
    {
        _secretKey = configuration["Stripe:SecretKey"];
        if (!string.IsNullOrWhiteSpace(_secretKey))
            _stripeClient = new StripeClient(_secretKey);
    }

    public bool IsConfigured => !string.IsNullOrWhiteSpace(_secretKey);

    /// <summary>
    /// Creates a Stripe PaymentIntent for the given amount. Amount is in the currency's smallest unit (e.g. cents for EUR/USD).
    /// </summary>
    public async Task<(string? ClientSecret, string? PaymentIntentId)> CreatePaymentIntentAsync(
        int reservationId,
        decimal amount,
        string currency = "eur",
        CancellationToken cancellationToken = default)
    {
        if (_stripeClient == null)
            throw new InvalidOperationException("Stripe is not configured. Set Stripe:SecretKey in configuration.");

        var amountInCents = (long)Math.Round(amount * 100);
        if (amountInCents < 50) // Stripe minimum
            amountInCents = 50;

        var options = new PaymentIntentCreateOptions
        {
            Amount = amountInCents,
            Currency = currency.ToLowerInvariant(),
            PaymentMethodTypes = new List<string> { "card" },
            Metadata = new Dictionary<string, string>
            {
                { "ReservationId", reservationId.ToString() }
            },
        };

        var service = new PaymentIntentService(_stripeClient);
        var intent = await service.CreateAsync(options, cancellationToken: cancellationToken);

        return (intent.ClientSecret, intent.Id);
    }

    /// <summary>
    /// Verifies that the PaymentIntent has succeeded (e.g. after client-side confirmation).
    /// </summary>
    public async Task<bool> PaymentSucceededAsync(string paymentIntentId, CancellationToken cancellationToken = default)
    {
        if (_stripeClient == null)
            return false;

        var service = new PaymentIntentService(_stripeClient);
        var intent = await service.GetAsync(paymentIntentId, cancellationToken: cancellationToken);
        return intent.Status == "succeeded";
    }
}
