using System;

namespace Yamore.Model
{
    /// <summary>Optional pending card payment row created in the same transaction as a new confirmed booking (Stripe card flow).</summary>
    public class CardPaymentPendingInfo
    {
        public decimal Amount { get; set; }
        public string PaymentMethod { get; set; } = "Card";
        public string Status { get; set; } = "pending";
        public DateTime? PaymentDateUtc { get; set; }
    }
}
