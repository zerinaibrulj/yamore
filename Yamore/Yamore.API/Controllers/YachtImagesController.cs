using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.YachtImage;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class YachtImagesController : ControllerBase
    {
        private readonly IYachtImageService _service;
        private readonly IYachtsService _yachts;

        public YachtImagesController(IYachtImageService service, IYachtsService yachts)
        {
            _service = service;
            _yachts = yachts;
        }

        [HttpGet("byYacht/{yachtId}")]
        [ProducesResponseType(typeof(PagedResponse<Model.YachtImage>), 200)]
        [ProducesResponseType(403)]
        public IActionResult GetByYacht(
            int yachtId,
            [FromQuery] int page = 0,
            [FromQuery] int pageSize = PagingConstraints.DefaultPageSize)
        {
            if (!CanAccessYacht(yachtId, readPublicCatalog: true, out var forbidden))
            {
                return forbidden!;
            }
            return Ok(_service.GetByYachtIdPaged(yachtId, page, pageSize));
        }

        [HttpGet("{imageId}")]
        public IActionResult GetImage(int imageId)
        {
            var entity = _service.GetRawById(imageId);
            if (entity == null)
            {
                return NotFound();
            }

            if (!CanAccessYacht(entity.YachtId, readPublicCatalog: true, out var forbidden))
            {
                return forbidden!;
            }

            return File(entity.ImageData, entity.ContentType);
        }

        [HttpPost("upload/{yachtId}")]
        [RequestSizeLimit(52_428_800)]
        [ProducesResponseType(typeof(Model.YachtImage), 200)]
        [ProducesResponseType(403)]
        public IActionResult Upload(int yachtId, [FromBody] YachtImageInsertRequest request)
        {
            if (!CanAccessYacht(yachtId, readPublicCatalog: false, out var forbidden))
            {
                return forbidden!;
            }

            var result = _service.Upload(yachtId, request);
            return Ok(result);
        }

        [HttpDelete("{imageId}")]
        public IActionResult Delete(int imageId)
        {
            var entity = _service.GetRawById(imageId);
            if (entity == null)
            {
                return NotFound();
            }

            if (!CanAccessYacht(entity.YachtId, readPublicCatalog: false, out var forbidden))
            {
                return forbidden!;
            }

            _service.Delete(imageId);
            return Ok();
        }

        [HttpPut("{imageId}/thumbnail")]
        public IActionResult SetThumbnail(int imageId)
        {
            var entity = _service.GetRawById(imageId);
            if (entity == null)
            {
                return NotFound();
            }

            if (!CanAccessYacht(entity.YachtId, readPublicCatalog: false, out var forbidden))
            {
                return forbidden!;
            }

            _service.SetThumbnail(imageId);
            return Ok();
        }

        /// <summary>Admin, yacht owner, or (for read) an authenticated user for active yachts in the public catalog.</summary>
        private bool CanAccessYacht(
            int yachtId,
            bool readPublicCatalog,
            out IActionResult? error)
        {
            error = null;
            var y = _yachts.GetById(yachtId);
            if (y == null)
            {
                error = NotFound();
                return false;
            }

            if (!int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var uid))
            {
                error = Unauthorized();
                return false;
            }

            if (User.IsInRole(AppRoles.Admin)
                || (y.OwnerId is { } o && o == uid))
            {
                return true;
            }

            if (readPublicCatalog
                && y.IsActive is true
                && string.Equals(y.StateMachine, YachtStateNames.Active, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            error = Forbid();
            return false;
        }
    }
}
