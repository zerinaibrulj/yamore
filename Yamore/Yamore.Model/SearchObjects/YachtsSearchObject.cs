using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.SearchObjects
{
    public class YachtsSearchObject : BaseSearchObject
    {
        public string? NameGTE { get; set; }
        public int? YearBuilt { get; set; }
        public int? Capacity { get; set; }
        public decimal? PricePerDay { get; set; }
        public string? OrderBy { get; set; }
    }
}
