using System;
using System.Collections.Generic;

namespace Yamore.Model.Requests.Payment
{
    /// <summary>Starts a card checkout without creating a reservation; the booking user is always the signed-in account (JWT).</summary>
    public class PrepareCardBookingRequest
    {
        public int YachtId { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public List<int> ServiceIds { get; set; } = new List<int>();
    }
}
