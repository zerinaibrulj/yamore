using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.Requests.SpecialRequest
{
    public class SpecialRequestInsertRequest
    {
        public int ReservationId { get; set; }
        public string Description { get; set; } = null!;
    }
}
