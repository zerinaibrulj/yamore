using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.Requests.ReservationService
{
    public class ReservationServiceUpdateRequest
    {
        public int ReservationId { get; set; }
        public int ServiceId { get; set; }
    }
}
