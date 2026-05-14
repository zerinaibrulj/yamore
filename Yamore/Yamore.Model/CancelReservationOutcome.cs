namespace Yamore.Model
{
    /// <summary>Result of cancelling a reservation.</summary>
    public class CancelReservationOutcome
    {
        public Reservation Reservation { get; set; } = null!;

        /// <summary>Reserved for API compatibility; paid-with-card bookings can no longer be cancelled via this flow.</summary>
        public bool HadCardPayment { get; set; }
    }
}
