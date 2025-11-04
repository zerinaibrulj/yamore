using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.SearchObjects
{
    public class PaymentSearchObject : BaseSearchObject
    {
        public int? ReservationId { get; set; }
        public string? PaymentMethod { get; set; }

        public string? Status { get; set; }
    }
}
