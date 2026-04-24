using System.Globalization;
using Stripe;
using Yamore.API.Configuration;

namespace Yamore.API.Services;

/// <summary>
/// Handles Stripe PaymentIntent creation and verification for card payments.
/// Configure Stripe:SecretKey and Stripe:PublishableKey via environment variables (Stripe__SecretKey, Stripe__PublishableKey)
/// or User Secrets — do not commit keys in appsettings.json.
/// </summary>
public class StripePaymentService
{
    private readonly string? _secretKey;
    private readonly StripeClient? _stripeClient;

    public StripePaymentService(IConfiguration configuration)
    {
        _secretKey = StripeKeyResolver.GetSecretKey(configuration);
        if (!string.IsNullOrWhiteSpace(_secretKey))
            _stripeClient = new StripeClient(_secretKey);
    }

    public bool IsConfigured => !string.IsNullOrWhiteSpace(_secretKey) && _secretKey.StartsWith("sk_", StringComparison.Ordinal);

    /// <summary>Smallest-currency amount Stripe will charge, matching <see cref="CreatePaymentIntentAsync"/> and provisional intents.</summary>
    public static long GetChargeAmountInCents(decimal amount)
    {
        var amountInCents = (long)Math.Round(amount * 100, MidpointRounding.AwayFromZero);
        if (amountInCents < 50) // Stripe minimum
            amountInCents = 50;
        return amountInCents;
    }

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

        var amountInCents = GetChargeAmountInCents(amount);

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

        return await CreateAndReturnAsync(options, cancellationToken);
    }

    /// <summary>Provisional card booking: no reservation row yet. Metadata is used by <c>POST Payment/confirm</c> to create the booking after success.</summary>
    public async Task<(string? ClientSecret, string? PaymentIntentId)> CreateProvisionalBookingIntentAsync(
        IReadOnlyDictionary<string, string> metadata,
        decimal amount,
        string currency = "eur",
        CancellationToken cancellationToken = default)
    {
        if (_stripeClient == null)
            throw new InvalidOperationException("Stripe is not configured. Set Stripe:SecretKey in configuration.");

        var amountInCents = GetChargeAmountInCents(amount);

        var options = new PaymentIntentCreateOptions
        {
            Amount = amountInCents,
            Currency = currency.ToLowerInvariant(),
            PaymentMethodTypes = new List<string> { "card" },
            Metadata = new Dictionary<string, string>(metadata),
        };

        return await CreateAndReturnAsync(options, cancellationToken);
    }

    private async Task<(string? ClientSecret, string? PaymentIntentId)> CreateAndReturnAsync(
        PaymentIntentCreateOptions options,
        CancellationToken cancellationToken)
    {
        if (_stripeClient == null)
            throw new InvalidOperationException("Stripe is not configured. Set Stripe:SecretKey in configuration.");
        var service = new PaymentIntentService(_stripeClient);
        var intent = await service.CreateAsync(options, cancellationToken: cancellationToken);
        return (intent.ClientSecret, intent.Id);
    }

    public async Task<PaymentIntent> GetPaymentIntentAsync(string paymentIntentId, CancellationToken cancellationToken = default)
    {
        if (_stripeClient == null)
            throw new InvalidOperationException("Stripe is not configured. Set Stripe:SecretKey in configuration.");
        return await new PaymentIntentService(_stripeClient).GetAsync(paymentIntentId, cancellationToken: cancellationToken);
    }

    /// <summary>Marks a provisional intent as fulfilled so repeat confirms are idempotent.</summary>
    public async Task TagPaymentIntentFulfilledAsync(
        string paymentIntentId,
        int reservationId,
        CancellationToken cancellationToken = default)
    {
        if (_stripeClient == null)
            return;
        var existing = await GetPaymentIntentAsync(paymentIntentId, cancellationToken);
        var merged = new Dictionary<string, string>(existing.Metadata ?? new Dictionary<string, string>())
        {
            ["FulfilledReservationId"] = reservationId.ToString(CultureInfo.InvariantCulture),
        };
        await new PaymentIntentService(_stripeClient).UpdateAsync(
            paymentIntentId,
            new PaymentIntentUpdateOptions { Metadata = merged },
            cancellationToken: cancellationToken);
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
