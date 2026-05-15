using System;

namespace Yamore.Model.Requests.Reservation
{
    /// <summary>New charter dates only; price and guest are determined server-side.</summary>
    public class ReservationRescheduleRequest
    {
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }
}
