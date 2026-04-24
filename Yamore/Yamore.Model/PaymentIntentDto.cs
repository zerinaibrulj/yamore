namespace Yamore.Model
{
    /// <summary>Placeholder for Stripe/PayPal payment intent. Replace with real gateway integration.</summary>
    public class PaymentIntentDto
    {
        public string? ClientSecret { get; set; }
        public string? PaymentIntentId { get; set; }
        public string? RedirectUrl { get; set; }
        public string? Status { get; set; }

        /// <summary>True when a repeat confirm is acknowledged without duplicating business effects (e.g. already finalized card payment for this reservation).</summary>
        public bool? AlreadyFinalized { get; set; }
    }

    public class CreatePaymentIntentRequest
    {
        public int ReservationId { get; set; }

        /// <summary>Ignored. The charge amount is always derived from the reservation on the server.</summary>
        public decimal Amount { get; set; }

        public string PaymentMethod { get; set; } = "stripe"; // "stripe" | "paypal"
    }

    public enum StripeWebhookHandleResult
    {
        /// <summary>Event ignored (wrong type) or not applicable.</summary>
        Skipped = 0,
        /// <summary>Handled successfully.</summary>
        Processed = 1,
        /// <summary>Webhook secret not set in configuration (request ignored, safe for Stripe 200 response).</summary>
        NotConfigured = 2,
    }

    public class ConfirmPaymentRequest
    {
        /// <summary>Required for card (Stripe) payments. Omit for cash/bank transfer.</summary>
        public string? PaymentIntentId { get; set; }

        public int ReservationId { get; set; }

        /// <summary>For offline payments: "cash" or "bank_transfer". Ignored when PaymentIntentId is set.</summary>
        public string? PaymentMethod { get; set; }
    }
}
