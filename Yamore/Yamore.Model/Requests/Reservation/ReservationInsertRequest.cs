using System;
using System.Collections.Generic;

namespace Yamore.Model.Requests.Reservation
{
    /// <summary>
    /// Self-service booking create. User, pricing, and initial status are determined only on the server.
    /// </summary>
    public class ReservationInsertRequest
    {
        public int YachtId { get; set; }

        public DateTime StartDate { get; set; }

        public DateTime EndDate { get; set; }

        /// <summary>Add-on services for this booking (must be linked to the yacht). Optional.</summary>
        public List<int>? ServiceIds { get; set; }
    }
}
