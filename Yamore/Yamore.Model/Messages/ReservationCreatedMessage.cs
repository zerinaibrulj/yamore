using System;

namespace Yamore.Model.Messages
{
    public class ReservationCreatedMessage
    {
        public int ReservationId { get; set; }
        public int UserId { get; set; }
        public int YachtId { get; set; }
        /// <summary>Display name of the yacht (for emails and notifications).</summary>
        public string? YachtName { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public decimal? TotalPrice { get; set; }
        public string? UserEmail { get; set; }
        public string? UserName { get; set; }
    }
}
