using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.Route;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class RouteController : BaseCRUDController<Model.Route, RouteSearchObject, RouteInsertRequest, RouteUpdateRequest, RouteDeleteRequest>
    {
        private readonly IYachtsService _yachtsService;

        public RouteController(IRouteService service, IYachtsService yachtsService)
            : base(service)
        {
            _yachtsService = yachtsService;
        }

        [HttpPost]
        public override ActionResult<Model.Route> Insert(RouteInsertRequest request)
        {
            if (!_yachtsService.CurrentUserMayManageYacht(request.YachtId))
                return Forbid();
            return base.Insert(request);
        }

        [HttpPut("{id}")]
        public override ActionResult<Model.Route> Update(int id, RouteUpdateRequest request)
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
        public override ActionResult<Model.Route> Delete(int id)
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
