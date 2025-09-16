using System;
using System.Collections.Generic;

namespace Yamore.Services.Database;

public partial class Notification
{
    public int NotificationId { get; set; }

    public int UserId { get; set; }

    public string Message { get; set; } = null!;

    public DateTime? CreatedAt { get; set; }

    public bool? IsRead { get; set; }

    public virtual User User { get; set; } = null!;
}
