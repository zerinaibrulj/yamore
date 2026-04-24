using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.Model.Api;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    /// <summary>
    /// One-time seed endpoint to add sample yacht data for testing the admin UI.
    /// </summary>
    [ApiController]
    [Route("[controller]")]
    public class SeedController : ControllerBase
    {
        private readonly ISampleYachtSeedService _sampleYachtSeedService;

        public SeedController(ISampleYachtSeedService sampleYachtSeedService)
        {
            _sampleYachtSeedService = sampleYachtSeedService;
        }

        [HttpPost("sample-yachts")]
        [AllowAnonymous]
        public ActionResult<SampleYachtSeedResponseDto> SeedSampleYachts()
        {
            var result = _sampleYachtSeedService.TrySeedSampleYachts();
            if (!result.Success)
            {
                return StatusCode(
                    result.StatusCode,
                    new SampleYachtSeedResponseDto { Message = result.Message });
            }
            if (result.Added != null)
            {
                return Ok(new SampleYachtSeedResponseDto
                {
                    Message = result.Message,
                    Added = result.Added
                });
            }
            return Ok(new SampleYachtSeedResponseDto
            {
                Message = result.Message,
                Count = result.Count
            });
        }
    }
}
