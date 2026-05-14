using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.YachtAvailability;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class YachtAvailabilityController : BaseCRUDController<YachtAvailability, YachtAvailabilitySearchObject, YachtAvailabilityInsertRequest, YachtAvailabilityUpdateRequest, YachtAvailabilityDeleteRequest>
    {
        private readonly IYachtsService _yachtsService;

        public YachtAvailabilityController(IYachtAvailabilityService service, IYachtsService yachtsService)
            : base(service)
        {
            _yachtsService = yachtsService;
        }

        [HttpPost]
        public override ActionResult<YachtAvailability> Insert(YachtAvailabilityInsertRequest request)
        {
            if (!_yachtsService.CurrentUserMayManageYacht(request.YachtId))
                return Forbid();
            return base.Insert(request);
        }

        [HttpPut("{id}")]
        public override ActionResult<YachtAvailability> Update(int id, YachtAvailabilityUpdateRequest request)
        {
            var existing = _service.GetById(id);
            if (existing == null)
                return NotFound();

            var oldYachtId = existing.YachtId;
            var newYachtId = request.YachtId ?? oldYachtId;

            if (!_yachtsService.CurrentUserMayManageYacht(oldYachtId)
                || !_yachtsService.CurrentUserMayManageYacht(newYachtId))
                return Forbid();

            return base.Update(id, request);
        }

        [HttpDelete("{id}")]
        public override ActionResult<YachtAvailability> Delete(int id)
        {
            var existing = _service.GetById(id);
            if (existing == null)
                return NotFound();

            if (!_yachtsService.CurrentUserMayManageYacht(existing.YachtId))
                return Forbid();

            return base.Delete(id);
        }
    }
}
