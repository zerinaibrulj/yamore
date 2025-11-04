using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.SearchObjects
{
    public class ReservationServiceSearchObject : BaseSearchObject
    {
        public int? ReservationServicesId { get; set; }
        public int? ReservationId { get; set; }
        public int? ServiceId { get; set; }
    }
}
