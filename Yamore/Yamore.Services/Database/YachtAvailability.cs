using System;

namespace Yamore.Services.Database;

public partial class YachtAvailability
{
    public int YachtAvailabilityId { get; set; }

    public int YachtId { get; set; }

    public DateTime StartDate { get; set; }

    public DateTime EndDate { get; set; }

    /// <summary>True = blocked (unavailable), False = available slot.</summary>
    public bool IsBlocked { get; set; }

    public string? Note { get; set; }

    public virtual Yacht Yacht { get; set; } = null!;
}
