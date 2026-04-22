using System;
using System.Collections.Generic;

namespace Yamore.Model.Requests.Payment
{
    /// <summary>Starts a card checkout without creating a reservation; the booking is written after successful Stripe payment in <c>POST Payment/confirm</c>.</summary>
    public class PrepareCardBookingRequest
    {
        public int UserId { get; set; }
        public int YachtId { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public List<int> ServiceIds { get; set; } = new List<int>();
    }
}
