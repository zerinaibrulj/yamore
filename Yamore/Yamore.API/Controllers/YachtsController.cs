using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class YachtsController : BaseCRUDController<Model.Yachts, YachtsSearchObject, YachtsInsertRequest, YachtsUpdateRequest>
    {
        public YachtsController(ICRUDService<Yachts, YachtsSearchObject, YachtsInsertRequest, YachtsUpdateRequest> service) 
            : base(service)
        {
        }
    }
}
