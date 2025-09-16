using System;
using System.Collections.Generic;

namespace Yamore.Services.Database;

public partial class Route
{
    public int RouteId { get; set; }

    public int YachtId { get; set; }

    public int StartCityId { get; set; }

    public int EndCityId { get; set; }

    public int? EstimatedDurationHours { get; set; }

    public string? Description { get; set; }

    public virtual City EndCity { get; set; } = null!;

    public virtual City StartCity { get; set; } = null!;

    public virtual ICollection<WeatherForecast> WeatherForecasts { get; set; } = new List<WeatherForecast>();

    public virtual Yacht Yacht { get; set; } = null!;
}
