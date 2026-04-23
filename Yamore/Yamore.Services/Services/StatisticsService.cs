using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using Yamore.Model;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class StatisticsService : IStatisticsService
    {
        private readonly _220245Context _context;

        public StatisticsService(_220245Context context)
        {
            _context = context;
        }

        public StatisticsDto GetAdminStatistics(int? year = null)
        {
            var reservations = _context.Reservations.AsQueryable();
            if (year.HasValue)
                reservations = reservations.Where(r => r.CreatedAt.HasValue && r.CreatedAt.Value.Year == year.Value);

            var cancelledOrRejected = new[] { "Cancelled" };
            var completedReservations = reservations.Where(r => r.Status != null && !cancelledOrRejected.Contains(r.Status));

            var totalBookings = completedReservations.Count();
            var totalRevenue = completedReservations.Sum(r => r.TotalPrice ?? 0);
            var activeUsersCount = _context.Users.Count(u => u.Status == true);
            var yachtsCount = _context.Yachts.Count(y => y.StateMachine == "active");
            var reportedReviewsCount = _context.Reviews.Count(r => r.IsReported);

            var yachtBookings = completedReservations
                .Where(r => r.Yacht != null)
                .Select(r => new
                {
                    r.YachtId,
                    YachtName = r.Yacht.Name,
                    r.TotalPrice
                })
                .GroupBy(x => new { x.YachtId, x.YachtName })
                .Select(g => new PopularYachtDto
                {
                    YachtId = g.Key.YachtId,
                    YachtName = g.Key.YachtName ?? string.Empty,
                    BookingCount = g.Count(),
                    TotalRevenue = g.Sum(x => x.TotalPrice ?? 0)
                })
                .OrderByDescending(x => x.BookingCount)
                .Take(10)
                .ToList();

            var revenueByMonth = completedReservations
                .Where(r => r.CreatedAt.HasValue)
                .GroupBy(r => new { r.CreatedAt!.Value.Year, r.CreatedAt.Value.Month })
                .Select(g => new RevenueByPeriodDto
                {
                    Year = g.Key.Year,
                    Month = g.Key.Month,
                    Revenue = g.Sum(r => r.TotalPrice ?? 0),
                    BookingCount = g.Count()
                })
                .OrderBy(x => x.Year).ThenBy(x => x.Month)
                .ToList();

            var reservationsByCity = completedReservations
                .Where(r => r.Yacht != null && r.Yacht.Location != null)
                .Select(r => new
                {
                    CityName = r.Yacht.Location.Name,
                    r.TotalPrice
                })
                .GroupBy(x => x.CityName)
                .Select(g => new ReservationsByCityDto
                {
                    CityName = g.Key,
                    ReservationCount = g.Count(),
                    Revenue = g.Sum(x => x.TotalPrice ?? 0)
                })
                .OrderByDescending(x => x.ReservationCount)
                .ToList();

            return new StatisticsDto
            {
                TotalBookings = totalBookings,
                TotalRevenue = totalRevenue,
                ActiveUsersCount = activeUsersCount,
                YachtsCount = yachtsCount,
                ReportedReviewsCount = reportedReviewsCount,
                MostPopularYachts = yachtBookings,
                RevenueByMonth = revenueByMonth,
                ReservationsByCity = reservationsByCity
            };
        }

        public OwnerRevenueDto GetOwnerRevenue(int ownerUserId)
        {
            var ownerYachtIds = _context.Yachts.Where(y => y.OwnerId == ownerUserId).Select(y => y.YachtId).ToList();
            var reservations = _context.Reservations
                .Where(r => ownerYachtIds.Contains(r.YachtId) && r.Status != null && r.Status != "Cancelled");

            var totalRevenue = reservations.Sum(r => r.TotalPrice ?? 0);
            var totalBookings = reservations.Count();

            var byYacht = reservations
                .GroupBy(r => new { r.YachtId, r.Yacht })
                .Select(g => new YachtRevenueDto
                {
                    YachtId = g.Key.YachtId,
                    YachtName = g.Key.Yacht != null ? g.Key.Yacht.Name : "",
                    BookingCount = g.Count(),
                    Revenue = g.Sum(r => r.TotalPrice ?? 0)
                })
                .ToList();

            return new OwnerRevenueDto
            {
                OwnerId = ownerUserId,
                TotalRevenue = totalRevenue,
                TotalBookings = totalBookings,
                RevenueByYacht = byYacht
            };
        }
    }
}
