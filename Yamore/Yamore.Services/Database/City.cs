using System;
using System.Collections.Generic;

namespace Yamore.Services.Database;

public partial class City
{
    public int CityId { get; set; }

    public int CountryId { get; set; }

    public string Name { get; set; } = null!;

    public virtual Country Country { get; set; } = null!;

    public virtual ICollection<Route> RouteEndCities { get; set; } = new List<Route>();

    public virtual ICollection<Route> RouteStartCities { get; set; } = new List<Route>();

    public virtual ICollection<Yacht> Yachts { get; set; } = new List<Yacht>();
}
