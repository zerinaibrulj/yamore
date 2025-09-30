using System;

namespace Yamore.Model
{
    public class Yacht
    {
        public int YachtId { get; set; }

        public int? OwnerId { get; set; }

        public string Name { get; set; } = null!;

        public string? Description { get; set; }

        public int? YearBuilt { get; set; }

        public decimal? Length { get; set; }

        public int Capacity { get; set; }

        public int? Cabins { get; set; }

        public int? Bathrooms { get; set; }

        public decimal PricePerDay { get; set; }

        public int? LocationId { get; set; }

        public int? CategoryId { get; set; }

        public bool? IsActive { get; set; }
    }
}
