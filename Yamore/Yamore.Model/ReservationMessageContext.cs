namespace Yamore.Model
{
    /// <summary>User and yacht display fields for reservation notifications (loaded from the database).</summary>
    public sealed class ReservationMessageContext
    {
        public string? UserEmail { get; set; }
        public string? UserDisplayName { get; set; }
        public string? YachtName { get; set; }
    }
}
