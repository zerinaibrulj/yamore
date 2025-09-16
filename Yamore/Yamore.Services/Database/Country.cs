using System;
using System.Collections.Generic;

namespace Yamore.Services.Database;

public partial class Country
{
    public int CountryId { get; set; }

    public string Name { get; set; } = null!;

    public virtual ICollection<City> Cities { get; set; } = new List<City>();
}
