using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.SpecialRequest;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class SpecialRequestController : BaseCRUDController<Model.SpecialRequest, SpecialRequestSearchObject, SpecialRequestInsertRequest, SpecialRequestUpdateRequest, SpecialRequestDeleteRequest>
    {
        public SpecialRequestController(ISpecialRequestService service) 
            : base(service)
        {
        }
    }
}
