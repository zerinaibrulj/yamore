using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.Requests.ReservationService
{
    public class ReservationServiceInsertRequest
    {
        public int ReservationId { get; set; }

        public int ServiceId { get; set; }
    }
}
