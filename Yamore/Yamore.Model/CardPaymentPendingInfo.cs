using System;

namespace Yamore.Model
{
    /// <summary>Optional card payment row created with a new confirmed booking; <see cref="Status"/> should be <c>succeeded</c> once Stripe confirms the charge.</summary>
    public class CardPaymentPendingInfo
    {
        public decimal Amount { get; set; }
        public string PaymentMethod { get; set; } = "Card";
        public string Status { get; set; } = PaymentStatuses.Success;
        public DateTime? PaymentDateUtc { get; set; }
    }
}
