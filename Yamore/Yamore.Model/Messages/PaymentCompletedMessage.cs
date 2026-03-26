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
    }
}
