using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.SearchObjects
{
    public class ReviewSearchObject : BaseSearchObject
    {
        public int? ReservationId { get; set; }

        public int? UserId { get; set; }

        public int? YachtId { get; set; }

        public int? Rating { get; set; }
    }
}
