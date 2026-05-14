using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.YachtService;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class YachtServiceController : BaseCRUDController<Model.YachtService, YachtServiceSearchObject, YachtServiceInsertRequest, YachtServiceUpdateRequest, YachtServiceDeleteRequest>
    {
        private readonly IYachtsService _yachtsService;

        public YachtServiceController(IYachtServiceService service, IYachtsService yachtsService)
            : base(service)
        {
            _yachtsService = yachtsService;
        }

        [HttpPost]
        public override ActionResult<Model.YachtService> Insert(YachtServiceInsertRequest request)
        {
            if (!_yachtsService.CurrentUserMayManageYacht(request.YachtId))
                return Forbid();
            return base.Insert(request);
        }

        [HttpPut("{id}")]
        public override ActionResult<Model.YachtService> Update(int id, YachtServiceUpdateRequest request)
        {
            var existing = _service.GetById(id);
            if (existing == null)
                return NotFound();

            if (!_yachtsService.CurrentUserMayManageYacht(existing.YachtId)
                || !_yachtsService.CurrentUserMayManageYacht(request.YachtId))
                return Forbid();

            return base.Update(id, request);
        }

        [HttpDelete("{id}")]
        public override ActionResult<Model.YachtService> Delete(int id)
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
