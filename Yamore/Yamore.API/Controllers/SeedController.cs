using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Hosting;
using Yamore.Model;
using Yamore.Model.Api;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    /// <summary>
    /// One-time seed endpoint to add sample yacht data (Development only, Admin only).
    /// </summary>
    [ApiController]
    [Route("[controller]")]
    [Authorize(Roles = AppRoles.Admin)]
    public class SeedController : ControllerBase
    {
        private readonly ISampleYachtSeedService _sampleYachtSeedService;
        private readonly IWebHostEnvironment _env;

        public SeedController(
            ISampleYachtSeedService sampleYachtSeedService,
            IWebHostEnvironment env)
        {
            _sampleYachtSeedService = sampleYachtSeedService;
            _env = env;
        }

        [HttpPost("sample-yachts")]
        public ActionResult<SampleYachtSeedResponseDto> SeedSampleYachts()
        {
            if (!_env.IsDevelopment())
            {
                return NotFound();
            }


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
