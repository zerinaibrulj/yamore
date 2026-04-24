using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.ServiceCategory;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class ServiceCategoryController : BaseCRUDController<ServiceCategory, ServiceCategorySearchObject, ServiceCategoryInsertRequest, ServiceCategoryUpdateRequest, ServiceCategoryDeleteRequest>
    {
        private readonly IServiceCategoryService _serviceCategoryService;

        public ServiceCategoryController(IServiceCategoryService service)
            : base(service)
        {
            _serviceCategoryService = service;
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public override ActionResult<ServiceCategory> Delete(int id)
        {
            var err = _serviceCategoryService.GetDeleteBlockingErrorMessage(id);
            if (err != null) return RejectWithUserError(err);
            return base.Delete(id);
        }

        [HttpGet]
        [AllowAnonymous]
        public override PagedResponse<ServiceCategory> GetPaged([FromQuery] ServiceCategorySearchObject search)
        {
            return base.GetPaged(search);
        }

        [HttpPost]
        [Authorize(Roles = AppRoles.Admin)]
        public override ActionResult<ServiceCategory> Insert(ServiceCategoryInsertRequest request)
        {
            return base.Insert(request);
        }
    }
}
