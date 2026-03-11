using System;

namespace Yamore.Model
{
    /// <summary>Admin overview: yacht with owner and location (city) names for list display.</summary>
    public class YachtOverviewDto
    {
        public int YachtId { get; set; }
        public string Name { get; set; } = null!;
        public string? LocationName { get; set; }
        public string? OwnerName { get; set; }
        public int? OwnerId { get; set; }
        public int? YearBuilt { get; set; }
        public decimal? Length { get; set; }
        public int Capacity { get; set; }
        public decimal PricePerDay { get; set; }
        public string? StateMachine { get; set; }
        public int? ThumbnailImageId { get; set; }
    }
}
