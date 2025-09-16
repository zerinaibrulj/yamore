using System;
using System.Collections.Generic;

namespace Yamore.Services.Database;

public partial class WeatherForecast
{
    public int ForecastId { get; set; }

    public int RouteId { get; set; }

    public DateOnly? ForecastDate { get; set; }

    public decimal? Temperature { get; set; }

    public string? Condition { get; set; }

    public decimal? WindSpeed { get; set; }

    public virtual Route Route { get; set; } = null!;
}
