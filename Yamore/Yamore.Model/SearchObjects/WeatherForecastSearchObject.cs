using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.SearchObjects
{
    public class WeatherForecastSearchObject : BaseSearchObject
    {
        public int? ForecastId { get; set; }

        public int? RouteId { get; set; }
    }
}
