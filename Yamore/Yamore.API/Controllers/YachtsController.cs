using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.YachtCategory;
using Yamore.Model.Requests.Yachts;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class YachtsController : BaseCRUDController<Model.Yacht, YachtsSearchObject, YachtsInsertRequest, YachtsUpdateRequest, YachtCategoryDeleteRequest>
    {
        public YachtsController(ICRUDService<Yacht, YachtsSearchObject, YachtsInsertRequest, YachtsUpdateRequest, YachtCategoryDeleteRequest> service) 
            : base(service)
        {
        }
    }
}
