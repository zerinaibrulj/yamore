using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.SearchObjects
{
    public class NotificationSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public bool? IsRead { get; set; }
    }
}
