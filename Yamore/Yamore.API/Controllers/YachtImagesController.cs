using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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

        public YachtImagesController(IYachtImageService service)
        {
            _service = service;
        }

        [HttpGet("byYacht/{yachtId}")]
        public ActionResult<List<Model.YachtImage>> GetByYacht(int yachtId)
        {
            return Ok(_service.GetByYachtId(yachtId));
        }

        [HttpGet("{imageId}")]
        [AllowAnonymous]
        public IActionResult GetImage(int imageId)
        {
            var entity = _service.GetRawById(imageId);
            if (entity == null)
                return NotFound();

            return File(entity.ImageData, entity.ContentType);
        }

        [HttpPost("upload/{yachtId}")]
        [RequestSizeLimit(52_428_800)]
        public ActionResult<Model.YachtImage> Upload(int yachtId, [FromBody] YachtImageInsertRequest request)
        {
            var result = _service.Upload(yachtId, request);
            return Ok(result);
        }

        [HttpDelete("{imageId}")]
        public IActionResult Delete(int imageId)
        {
            _service.Delete(imageId);
            return Ok();
        }

        [HttpPut("{imageId}/thumbnail")]
        public IActionResult SetThumbnail(int imageId)
        {
            _service.SetThumbnail(imageId);
            return Ok();
        }
    }
}
