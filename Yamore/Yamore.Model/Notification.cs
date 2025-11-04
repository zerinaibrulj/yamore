using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model
{
    public class Notification
    {
        public int NotificationId { get; set; }

        public int UserId { get; set; }

        public string Message { get; set; } = null!;

        public DateTime? CreatedAt { get; set; }

        public bool? IsRead { get; set; }
    }
}
