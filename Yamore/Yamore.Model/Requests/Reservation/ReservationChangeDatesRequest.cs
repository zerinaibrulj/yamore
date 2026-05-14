using System;

namespace Yamore.Model.Requests.Reservation
{
    /// <summary>Change charter dates for a <b>pending</b> reservation; server recalculates total from yacht + duration + existing add-ons.</summary>
    public class ReservationChangeDatesRequest
    {
        public DateTime StartDate { get; set; }

        public DateTime EndDate { get; set; }
    }
}
