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
        public YachtServiceController(IYachtServiceService service)
            : base(service)
        {
        }

        [HttpGet]
        [AllowAnonymous]
        public override PagedResponse<YachtService> GetPaged([FromQuery] YachtServiceSearchObject search)
        {
            return base.GetPaged(search);
        }
    }
}
