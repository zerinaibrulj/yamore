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
            var countableReservations = CountableReservations(year);
            var reportablePayments = ReportablePayments(year);

            var totalRevenue = reportablePayments.Sum(p => (decimal?)p.Amount) ?? 0m;
            var totalBookings = countableReservations.Count();

            var activeUsersCount = _context.Users.Count(u => u.Status == true);
            var yachtsCount = _context.Yachts.Count(y => y.StateMachine == "active");

            var reportedReviewsQuery = _context.Reviews.Where(r => r.IsReported);
            if (year.HasValue)
            {
                reportedReviewsQuery = reportedReviewsQuery.Where(r =>
                    r.DatePosted.HasValue && r.DatePosted.Value.Year == year.Value);
            }

            var reportedReviewsCount = reportedReviewsQuery.Count();

            var revenueByYacht = reportablePayments
                .Join(
                    _context.Reservations.AsNoTracking(),
                    p => p.ReservationId,
                    r => r.ReservationId,
                    (p, r) => new { p.Amount, r.YachtId })
                .GroupBy(x => x.YachtId)
                .ToDictionary(g => g.Key, g => g.Sum(x => x.Amount));

            var yachtBookings = (
                    from r in countableReservations
                    join y in _context.Yachts.AsNoTracking() on r.YachtId equals y.YachtId
                    group r by new { y.YachtId, YachtName = y.Name } into g
                    select new
                    {
                        g.Key.YachtId,
                        g.Key.YachtName,
                        BookingCount = g.Count(),
                    })
                .ToList()
                .Select(x => new PopularYachtDto
                {
                    YachtId = x.YachtId,
                    YachtName = x.YachtName ?? string.Empty,
                    BookingCount = x.BookingCount,
                    TotalRevenue = revenueByYacht.TryGetValue(x.YachtId, out var rev) ? rev : 0m,
                })
                .OrderByDescending(x => x.BookingCount)
                .ThenByDescending(x => x.TotalRevenue)
                .Take(10)
                .ToList();

            var revenueByMonth = BuildRevenueByMonth(
                reportablePayments,
                countableReservations.ToList());

            var revenueByCity = reportablePayments
                .Join(
                    _context.Reservations.AsNoTracking(),
                    p => p.ReservationId,
                    r => r.ReservationId,
                    (p, r) => new { p.Amount, r.YachtId })
                .Join(
                    _context.Yachts.AsNoTracking(),
                    x => x.YachtId,
                    y => y.YachtId,
                    (x, y) => new { x.Amount, y.LocationId })
                .Join(
                    _context.Cities.AsNoTracking(),
                    x => x.LocationId,
                    c => c.CityId,
                    (x, c) => new { x.Amount, CityName = c.Name })
                .GroupBy(x => x.CityName)
                .ToDictionary(g => g.Key ?? string.Empty, g => g.Sum(x => x.Amount));

            var reservationsByCity = (
                    from r in countableReservations
                    join y in _context.Yachts.AsNoTracking() on r.YachtId equals y.YachtId
                    join loc in _context.Cities.AsNoTracking() on y.LocationId equals loc.CityId
                    group r by loc.Name into g
                    select new
                    {
                        CityName = g.Key ?? string.Empty,
                        ReservationCount = g.Count(),
                    })
                .ToList()
                .Select(x => new ReservationsByCityDto
                {
                    CityName = x.CityName,
                    ReservationCount = x.ReservationCount,
                    Revenue = revenueByCity.TryGetValue(x.CityName, out var rev) ? rev : 0m,
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
                ReservationsByCity = reservationsByCity,
            };
        }

        public OwnerRevenueDto GetOwnerRevenue(int ownerUserId)
        {
            var ownerYachtIds = _context.Yachts
                .AsNoTracking()
                .Where(y => y.OwnerId == ownerUserId)
                .Select(y => y.YachtId)
                .ToList();

            if (ownerYachtIds.Count == 0)
            {
                return new OwnerRevenueDto
                {
                    OwnerId = ownerUserId,
                    TotalRevenue = 0,
                    TotalBookings = 0,
                    RevenueByYacht = new List<YachtRevenueDto>(),
                };
            }

            var reportablePayments = _context.Payments
                .AsNoTracking()
                .Join(
                    _context.Reservations.AsNoTracking(),
                    p => p.ReservationId,
                    r => r.ReservationId,
                    (p, r) => new { p, r })
                .Where(x => ownerYachtIds.Contains(x.r.YachtId)
                    && (x.r.Status == null || x.r.Status != ReservationStatuses.Cancelled)
                    && x.p.Amount > 0
                    && x.p.Status != null
                    && (x.p.Status.ToLower() == PaymentStatuses.Success.ToLower()
                        || x.p.Status.ToLower() == PaymentStatuses.StripeSucceeded
                        || x.p.Status.ToLower() == PaymentStatuses.Paid
                        || (x.p.Status.ToLower() == PaymentStatuses.Pending.ToLower()
                            || x.p.Status.ToLower() == "pending"
                            && x.p.PaymentMethod != null
                            && x.p.PaymentMethod.ToLower().Contains("card")
                            && x.r.Status != null
                            && (x.r.Status.ToLower() == ReservationStatuses.Confirmed.ToLower()
                                || x.r.Status.ToLower() == ReservationStatuses.Completed.ToLower()))))
                .Select(x => new { x.p.Amount, x.p.ReservationId, x.r.YachtId });

            var totalRevenue = reportablePayments.Sum(x => (decimal?)x.Amount) ?? 0m;
            var totalBookings = _context.Reservations
                .AsNoTracking()
                .Where(r => ownerYachtIds.Contains(r.YachtId)
                    && (r.Status == null || r.Status != ReservationStatuses.Cancelled))
                .Count();

            var byYacht = reportablePayments
                .Join(
                    _context.Yachts.AsNoTracking(),
                    x => x.YachtId,
                    y => y.YachtId,
                    (x, y) => new { x.ReservationId, x.Amount, y.YachtId, y.Name })
                .GroupBy(x => new { x.YachtId, x.Name })
                .Select(g => new YachtRevenueDto
                {
                    YachtId = g.Key.YachtId,
                    YachtName = g.Key.Name ?? string.Empty,
                    BookingCount = g.Select(x => x.ReservationId).Distinct().Count(),
                    Revenue = g.Sum(x => x.Amount),
                })
                .ToList();

            return new OwnerRevenueDto
            {
                OwnerId = ownerUserId,
                TotalRevenue = totalRevenue,
                TotalBookings = totalBookings,
                RevenueByYacht = byYacht,
            };
        }

        /// <summary>
        /// Payments that count as revenue: succeeded/paid, or card + pending on a confirmed/completed booking.
        /// Year filter matches payment date or any reservation activity date in that calendar year.
        /// </summary>
        private IQueryable<Database.Payment> ReportablePayments(int? year)
        {
            var query = _context.Payments
                .AsNoTracking()
                .Join(
                    _context.Reservations.AsNoTracking(),
                    p => p.ReservationId,
                    r => r.ReservationId,
                    (p, r) => new { p, r })
                .Where(x => x.p.Amount > 0
                    && (x.r.Status == null || x.r.Status != ReservationStatuses.Cancelled)
                    && x.p.Status != null
                    && (x.p.Status.ToLower() == PaymentStatuses.Success.ToLower()
                        || x.p.Status.ToLower() == PaymentStatuses.StripeSucceeded
                        || x.p.Status.ToLower() == PaymentStatuses.Paid
                        || (x.p.Status.ToLower() == PaymentStatuses.Pending.ToLower()
                            || x.p.Status.ToLower() == "pending"
                            && x.p.PaymentMethod != null
                            && x.p.PaymentMethod.ToLower().Contains("card")
                            && x.r.Status != null
                            && (x.r.Status.ToLower() == ReservationStatuses.Confirmed.ToLower()
                                || x.r.Status.ToLower() == ReservationStatuses.Completed.ToLower()))))
                .Select(x => new { x.p, x.r });

            if (!year.HasValue)
                return query.Select(x => x.p);

            var y = year.Value;
            return query
                .Where(x =>
                    x.p.PaymentDate.Year == y
                    || (x.r.CreatedAt.HasValue && x.r.CreatedAt.Value.Year == y)
                    || x.r.StartDate.Year == y
                    || x.r.EndDate.Year == y)
                .Select(x => x.p);
        }

        /// <summary>Non-cancelled reservations for booking charts and counts.</summary>
        private IQueryable<Database.Reservation> CountableReservations(int? year)
        {
            var query = _context.Reservations
                .AsNoTracking()
                .Where(r => r.Status == null || r.Status != ReservationStatuses.Cancelled);

            if (!year.HasValue)
                return query;

            var y = year.Value;
            return query.Where(r =>
                (r.CreatedAt.HasValue && r.CreatedAt.Value.Year == y)
                || r.StartDate.Year == y
                || r.EndDate.Year == y);
        }

        private static List<RevenueByPeriodDto> BuildRevenueByMonth(
            IQueryable<Database.Payment> reportablePayments,
            List<Database.Reservation> countableReservations)
        {
            var revenueMonths = reportablePayments
                .GroupBy(p => new { p.PaymentDate.Year, p.PaymentDate.Month })
                .Select(g => new
                {
                    g.Key.Year,
                    g.Key.Month,
                    Revenue = g.Sum(p => p.Amount),
                })
                .ToList();

            var bookingMonths = countableReservations
                .GroupBy(r =>
                {
                    var d = r.CreatedAt ?? r.StartDate;
                    return new { d.Year, d.Month };
                })
                .Select(g => new
                {
                    g.Key.Year,
                    g.Key.Month,
                    BookingCount = g.Count(),
                })
                .ToList();

            var keys = revenueMonths
                .Select(x => (x.Year, x.Month))
                .Union(bookingMonths.Select(x => (x.Year, x.Month)))
                .Distinct()
                .OrderBy(k => k.Year)
                .ThenBy(k => k.Month);

            var revenueLookup = revenueMonths.ToDictionary(x => (x.Year, x.Month), x => x.Revenue);
            var bookingLookup = bookingMonths.ToDictionary(x => (x.Year, x.Month), x => x.BookingCount);

            return keys
                .Select(k => new RevenueByPeriodDto
                {
                    Year = k.Year,
                    Month = k.Month,
                    Revenue = revenueLookup.TryGetValue(k, out var rev) ? rev : 0m,
                    BookingCount = bookingLookup.TryGetValue(k, out var bc) ? bc : 0,
                })
                .ToList();
        }
    }
}
