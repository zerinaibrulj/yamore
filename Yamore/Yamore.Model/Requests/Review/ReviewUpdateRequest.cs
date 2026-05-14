using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.Requests.Review
{
    public class ReviewUpdateRequest
    {
        public int ReservationId { get; set; }

        public int YachtId { get; set; }

        public int? Rating { get; set; }

        public string? Comment { get; set; }

        public string? OwnerResponse { get; set; }

        public DateTime? OwnerResponseDate { get; set; }
    }
}
