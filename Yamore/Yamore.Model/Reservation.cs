using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model
{
    public class Reservation
    {
        public int ReservationId { get; set; }

        public int UserId { get; set; }

        public int YachtId { get; set; }

        public DateTime StartDate { get; set; }

        public DateTime EndDate { get; set; }

        public decimal? TotalPrice { get; set; }

        public string? Status { get; set; }

        public DateTime? CreatedAt { get; set; }

        public virtual User User { get; set; } = null!;

        public virtual Yacht Yacht { get; set; } = null!;
    }
}
