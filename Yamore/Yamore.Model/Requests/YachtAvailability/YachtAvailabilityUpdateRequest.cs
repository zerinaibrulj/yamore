using System;

namespace Yamore.Model.Requests.YachtAvailability
{
    public class YachtAvailabilityUpdateRequest
    {
        public int? YachtId { get; set; }

        public DateTime? StartDate { get; set; }

        public DateTime? EndDate { get; set; }

        public bool? IsBlocked { get; set; }

        public string? Note { get; set; }
    }
}
