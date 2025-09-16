using System;
using System.Collections.Generic;

namespace Yamore.Services.Database;

public partial class Review
{
    public int ReviewId { get; set; }

    public int ReservationId { get; set; }

    public int UserId { get; set; }

    public int YachtId { get; set; }

    public int? Rating { get; set; }

    public string? Comment { get; set; }

    public DateTime? DatePosted { get; set; }

    public virtual Reservation Reservation { get; set; } = null!;

    public virtual User User { get; set; } = null!;

    public virtual Yacht Yacht { get; set; } = null!;
}
