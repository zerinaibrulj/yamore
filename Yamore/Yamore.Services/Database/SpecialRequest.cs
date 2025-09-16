using System;
using System.Collections.Generic;

namespace Yamore.Services.Database;

public partial class SpecialRequest
{
    public int RequestId { get; set; }

    public int ReservationId { get; set; }

    public string Description { get; set; } = null!;

    public virtual Reservation Reservation { get; set; } = null!;
}
