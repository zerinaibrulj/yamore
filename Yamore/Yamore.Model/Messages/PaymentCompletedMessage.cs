using System;

namespace Yamore.Model.Messages
{
    public class PaymentCompletedMessage
    {
        public int PaymentId { get; set; }
        public int ReservationId { get; set; }
        public decimal Amount { get; set; }
        public string? PaymentMethod { get; set; }
        public string? PaymentStatus { get; set; }
        public bool IsConfirmed { get; set; }
        public string? UserEmail { get; set; }
        /// <summary>Full name of the customer (for email greeting).</summary>
        public string? UserName { get; set; }
        /// <summary>Display name of the yacht (for emails and notifications).</summary>
        public string? YachtName { get; set; }
        /// <summary>Charter / booking start (trip period).</summary>
        public DateTime? ReservationStartDate { get; set; }
        /// <summary>Charter / booking end (trip period).</summary>
        public DateTime? ReservationEndDate { get; set; }
    }
}
