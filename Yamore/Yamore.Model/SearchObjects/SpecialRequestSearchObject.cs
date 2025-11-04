using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.SearchObjects
{
    public class SpecialRequestSearchObject : BaseSearchObject
    {
        public int? RequestId { get; set; }

        public int? ReservationId { get; set; }

        public string? Description { get; set; } 
    }
}
