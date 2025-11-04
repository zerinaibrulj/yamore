using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model
{
    public class SpecialRequest
    {
        public int RequestId { get; set; }

        public int ReservationId { get; set; }

        public string Description { get; set; } = null!;
    }
}
