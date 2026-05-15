using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.YachtDocument;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("Yacht")]
    [Authorize]
    public class YachtDocumentsController : ControllerBase
    {
        private readonly IYachtDocumentService _documents;
        private readonly IYachtsService _yachts;

        public YachtDocumentsController(IYachtDocumentService documents, IYachtsService yachts)
        {
            _documents = documents;
            _yachts = yachts;
        }

        [HttpGet("{id}/documents")]
        public IActionResult List(int id)
        {
            if (!CanViewDocuments(id, out var error))
                return error!;
            return Ok(_documents.GetByYachtId(id));
        }

        [HttpGet("documents/{docId}/file")]
        public IActionResult Download(int docId)
        {
            var entity = _documents.GetEntity(docId);
            if (entity == null)
                return NotFound();
            if (!CanViewDocuments(entity.YachtId, out var error))
                return error!;
            var bytes = _documents.GetFileContent(docId);
            if (bytes == null || bytes.Length == 0)
                return NotFound();
            return File(bytes, entity.ContentType, entity.FileName ?? $"document-{docId}");
        }

        [HttpPost("{id}/documents")]
        [Authorize(Roles = AppRoles.YachtOwner)]
        [RequestSizeLimit(12_582_912)]
        public IActionResult Upload(int id, [FromBody] YachtDocumentInsertRequest request)
        {
            if (!int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId))
                return Unauthorized();
            if (!_yachts.YachtExists(id))
                return NotFound();
            if (!_yachts.CurrentUserMayManageYacht(id))
                return Forbid();
            var doc = _documents.Upload(id, userId, request);
            return Ok(doc);
        }

        [HttpPut("documents/{docId}/verify")]
        [Authorize(Roles = AppRoles.Admin)]
        public IActionResult Verify(int docId, [FromBody] YachtDocumentVerifyRequest request)
        {
            if (!int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var adminId))
                return Unauthorized();
            var doc = _documents.Verify(docId, adminId, request);
            return Ok(doc);
        }

        [HttpGet("documents/pending")]
        [Authorize(Roles = AppRoles.Admin)]
        public IActionResult ListPending() => Ok(_documents.GetPendingForAdmin());

        private bool CanViewDocuments(int yachtId, out IActionResult? error)
        {
            error = null;
            if (!_yachts.YachtExists(yachtId))
            {
                error = NotFound();
                return false;
            }

            if (User.IsInRole(AppRoles.Admin))
                return true;
            if (_yachts.CurrentUserMayManageYacht(yachtId))
                return true;
            error = Forbid();
            return false;
        }
    }
}
