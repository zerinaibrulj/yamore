using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.Requests.Notification
{
    public class NotificationUpdateRequest
    {
        public int UserId { get; set; }

        public string Message { get; set; } = null!;

        public DateTime? CreatedAt { get; set; }

        public bool? IsRead { get; set; }
    }
}
