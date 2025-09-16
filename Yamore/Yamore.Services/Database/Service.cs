using System;
using System.Collections.Generic;

namespace Yamore.Services.Database;

public partial class Service
{
    public int ServiceId { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public decimal? Price { get; set; }

    public virtual ICollection<ReservationService> ReservationServices { get; set; } = new List<ReservationService>();
}
