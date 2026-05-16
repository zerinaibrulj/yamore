using System;

namespace Yamore.Model
{
    /// <summary>Admin overview: yacht with owner and location (city) names for list display.</summary>
    public class YachtOverviewDto
    {
        public int YachtId { get; set; }
        public string Name { get; set; } = null!;
        public string? LocationName { get; set; }
        public string? CountryName { get; set; }
        public string? OwnerName { get; set; }
        public int? OwnerId { get; set; }
        public int? YearBuilt { get; set; }
        public decimal? Length { get; set; }
        public int Capacity { get; set; }
        public decimal PricePerDay { get; set; }
        public string? StateMachine { get; set; }
        public int? ThumbnailImageId { get; set; }
        public int CategoryId { get; set; }
        public double? AverageRating { get; set; }
        public int ReviewCount { get; set; }

        /// <summary>Short, user-facing explanation for explainable recommendations (content-based / popularity).</summary>
        public string? RecommendationReason { get; set; }

        /// <summary>True when the yacht is in draft and all mandatory documents are admin-approved (may call Activate).</summary>
        public bool CanActivate { get; set; }
    }
}
