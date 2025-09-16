using System;
using System.Collections.Generic;

namespace Yamore.Services.Database;

public partial class ReservationService
{
    public int ReservationServicesId { get; set; }

    public int ReservationId { get; set; }

    public int ServiceId { get; set; }

    public virtual Reservation Reservation { get; set; } = null!;

    public virtual Service Service { get; set; } = null!;
}
