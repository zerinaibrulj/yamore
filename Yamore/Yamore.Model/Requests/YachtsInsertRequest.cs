using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.Requests
{
    public class YachtsInsertRequest
    {
        public string Name { get; set; } = null!;
        public int? YearBuilt { get; set; }
        public decimal? Length { get; set; }
        public int? Capacity { get; set; }
        public decimal? PricePerDay { get; set; } 
    }
}
