using Yamore.Model;

namespace Yamore.Services.Interfaces
{
    public interface IStatisticsService
    {
        StatisticsDto GetAdminStatistics(int? year = null);
        OwnerRevenueDto GetOwnerRevenue(int ownerUserId);
    }
}
