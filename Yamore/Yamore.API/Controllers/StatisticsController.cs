using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class StatisticsController : ControllerBase
    {
        private readonly IStatisticsService _statisticsService;

        public StatisticsController(IStatisticsService statisticsService)
        {
            _statisticsService = statisticsService;
        }

        [HttpGet("admin")]
        [Authorize(Roles = "Admin")]
        public StatisticsDto GetAdminStatistics([FromQuery] int? year)
        {
            return _statisticsService.GetAdminStatistics(year);
        }

        [HttpGet("owner/revenue")]
        [Authorize(Roles = "Admin,YachtOwner")]
        public ActionResult<OwnerRevenueDto> GetOwnerRevenue()
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var ownerId))
                return Unauthorized();
            return Ok(_statisticsService.GetOwnerRevenue(ownerId));
        }
    }
}
