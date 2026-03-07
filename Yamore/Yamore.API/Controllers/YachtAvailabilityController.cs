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
        public YachtAvailabilityController(IYachtAvailabilityService service)
            : base(service)
        {
        }
    }
}
