using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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
        public ActionResult<object> SeedSampleYachts()
        {
            var result = _sampleYachtSeedService.TrySeedSampleYachts();
            if (!result.Success)
                return StatusCode(result.StatusCode, new { message = result.Message });
            if (result.Added != null)
                return Ok(new { message = result.Message, added = result.Added });
            return Ok(new { message = result.Message, count = result.Count });
        }
    }
}
