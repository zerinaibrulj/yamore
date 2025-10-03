using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.SearchObjects
{
    public class RouteSearchObject : BaseSearchObject
    {
        public int StartCityId { get; set; }

        public int EndCityId { get; set; }

        public int? EstimatedDurationHours { get; set; }
    }
}
