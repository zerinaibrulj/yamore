using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.YachtCategory;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class YachtCategoryController : BaseCRUDController<Model.YachtCategory, YachtCategorySearchObject, YachtCategoryInsertRequest, YachtCategoryUpdateRequest, YachtCategoryDeleteRequest>
    {
        private readonly IYachtCategoryService _yachtCategoryService;

        public YachtCategoryController(IYachtCategoryService service)
            : base(service)
        {
            _yachtCategoryService = service;
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public override ActionResult<YachtCategory> Delete(int id)
        {
            var err = _yachtCategoryService.GetDeleteBlockingErrorMessage(id);
            if (err != null) return RejectWithUserError(err);
            return base.Delete(id);
        }

        [Authorize(Roles = AppRoles.Admin)]
        public override ActionResult<YachtCategory> Insert(YachtCategoryInsertRequest request)
        {
            return base.Insert(request);
        }

        /// <summary>Anonymous listing for browse and booking flows.</summary>
        [AllowAnonymous]
        public override PagedResponse<YachtCategory> GetPaged([FromQuery] YachtCategorySearchObject search)
        {
            return base.GetPaged(search);
        }
    }
}
