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
        public ServiceCategoryController(IServiceCategoryService service)
            : base(service)
        {
        }

        [HttpGet]
        [AllowAnonymous]
        public override PagedResponse<ServiceCategory> GetPaged([FromQuery] ServiceCategorySearchObject search)
        {
            return base.GetPaged(search);
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public override ActionResult<ServiceCategory> Insert(ServiceCategoryInsertRequest request)
        {
            return base.Insert(request);
        }
    }
}
