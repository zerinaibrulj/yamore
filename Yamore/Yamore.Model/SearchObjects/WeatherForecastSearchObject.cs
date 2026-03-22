using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.SearchObjects
{
    public class WeatherForecastSearchObject : BaseSearchObject
    {
        public int? ForecastId { get; set; }

        public int? RouteId { get; set; }

        /// <summary>Optional: limit forecasts to calendar days overlapping the yacht trip (inclusive).</summary>
        public DateTime? TripStart { get; set; }

        public DateTime? TripEnd { get; set; }
    }
}
