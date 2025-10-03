using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model
{
    public class Route
    {
        public int RouteId { get; set; }

        public int YachtId { get; set; }

        public int StartCityId { get; set; }

        public int EndCityId { get; set; }

        public int? EstimatedDurationHours { get; set; }

        public string? Description { get; set; }
    }
}
