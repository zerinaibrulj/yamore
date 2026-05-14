using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.Requests.Yachts
{
    public class YachtsUpdateRequest
    {
        /// <summary>Owner cannot be changed through the standard update API; use admin update.</summary>
        public string Name { get; set; } = null!;

        public string? Description { get; set; }

        public int YearBuilt { get; set; }

        public decimal Length { get; set; }

        public int Capacity { get; set; }

        public int Cabins { get; set; }

        public int? Bathrooms { get; set; }

        public decimal PricePerDay { get; set; }

        public int LocationId { get; set; }

        public int CategoryId { get; set; }

        public bool? IsActive { get; set; }
    }
}
