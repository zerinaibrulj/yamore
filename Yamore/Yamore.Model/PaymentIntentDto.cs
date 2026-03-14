namespace Yamore.Model
{
    /// <summary>Placeholder for Stripe/PayPal payment intent. Replace with real gateway integration.</summary>
    public class PaymentIntentDto
    {
        public string? ClientSecret { get; set; }
        public string? PaymentIntentId { get; set; }
        public string? RedirectUrl { get; set; }
        public string? Status { get; set; }
    }

    public class CreatePaymentIntentRequest
    {
        public int ReservationId { get; set; }
        public decimal Amount { get; set; }
        public string PaymentMethod { get; set; } = "stripe"; // "stripe" | "paypal"
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
