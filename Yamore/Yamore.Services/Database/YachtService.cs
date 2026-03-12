using System;
using System.Collections.Generic;

namespace Yamore.Services.Database;

public partial class YachtService
{
    public int YachtServiceId { get; set; }

    public int YachtId { get; set; }

    public int ServiceId { get; set; }

    public virtual Yacht Yacht { get; set; } = null!;

    public virtual Service Service { get; set; } = null!;
}
