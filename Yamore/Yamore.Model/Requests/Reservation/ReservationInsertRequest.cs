using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.Requests.Reservation
{
    public class ReservationInsertRequest
    {
        public int UserId { get; set; }

        public int YachtId { get; set; }

        public DateTime StartDate { get; set; }

        public DateTime EndDate { get; set; }

        public decimal? TotalPrice { get; set; }

        public string? Status { get; set; }
        public DateTime? CreatedAt { get; set; }
    }
}
