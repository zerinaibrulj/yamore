using System;
using System.Collections.Generic;

namespace Yamore.Model
{
    /// <summary>Admin dashboard statistics.</summary>
    public class StatisticsDto
    {
        public int TotalBookings { get; set; }
        public decimal TotalRevenue { get; set; }
        public int ActiveUsersCount { get; set; }
        public int YachtsCount { get; set; }
        public int ReportedReviewsCount { get; set; }
        public List<PopularYachtDto> MostPopularYachts { get; set; } = new List<PopularYachtDto>();
        public List<RevenueByPeriodDto> RevenueByMonth { get; set; } = new List<RevenueByPeriodDto>();
    }

    public class PopularYachtDto
    {
        public int YachtId { get; set; }
        public string YachtName { get; set; } = null!;
        public int BookingCount { get; set; }
        public decimal TotalRevenue { get; set; }
    }

    public class RevenueByPeriodDto
    {
        public int Year { get; set; }
        public int Month { get; set; }
        public decimal Revenue { get; set; }
        public int BookingCount { get; set; }
    }

    /// <summary>Owner dashboard: bookings and revenue for owner's yachts.</summary>
    public class OwnerRevenueDto
    {
        public int OwnerId { get; set; }
        public decimal TotalRevenue { get; set; }
        public int TotalBookings { get; set; }
        public List<YachtRevenueDto> RevenueByYacht { get; set; } = new List<YachtRevenueDto>();
    }

    public class YachtRevenueDto
    {
        public int YachtId { get; set; }
        public string YachtName { get; set; } = null!;
        public int BookingCount { get; set; }
        public decimal Revenue { get; set; }
    }
}
