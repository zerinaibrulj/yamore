namespace Yamore.Model
{
    /// <summary>Result of cancelling a reservation (includes flag for client messaging, e.g. card refunds).</summary>
    public class CancelReservationOutcome
    {
        public Reservation Reservation { get; set; } = null!;

        /// <summary>True if a card payment with amount was on file before cancel (for user-facing copy).</summary>
        public bool HadCardPayment { get; set; }
    }
}
