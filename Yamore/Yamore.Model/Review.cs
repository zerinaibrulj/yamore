using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model
{
    public class Review
    {
        public int ReviewId { get; set; }

        public int ReservationId { get; set; }

        public int UserId { get; set; }

        public int YachtId { get; set; }

        public int? Rating { get; set; }

        public string? Comment { get; set; }

        public DateTime? DatePosted { get; set; }

        public string? OwnerResponse { get; set; }

        public DateTime? OwnerResponseDate { get; set; }

        public bool IsReported { get; set; }
    }
}
