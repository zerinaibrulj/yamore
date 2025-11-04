using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.Requests.SpecialRequest
{
    public class SpecialRequestUpdateRequest
    {
        public int ReservationId { get; set; }

        public string Description { get; set; } = null!;
    }
}
