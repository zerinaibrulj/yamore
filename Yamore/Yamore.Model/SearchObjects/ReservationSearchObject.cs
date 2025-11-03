using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.SearchObjects
{
    public class ReservationSearchObject : BaseSearchObject
    {
        public int ReservationId { get; set; }

        public int UserId { get; set; }

        public int YachtId { get; set; }
    }
}
