using System;

namespace Yamore.Model.SearchObjects
{
    public class YachtAvailabilitySearchObject : BaseSearchObject
    {
        public int? YachtId { get; set; }

        public DateTime? StartDateFrom { get; set; }

        public DateTime? EndDateTo { get; set; }

        public bool? IsBlocked { get; set; }
    }
}
