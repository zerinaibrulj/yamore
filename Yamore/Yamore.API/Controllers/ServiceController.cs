using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.Service;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ServiceController : BaseCRUDController<Model.Service, ServiceSearchObject, ServiceInsertRequest, ServiceUpdateRequest, ServiceDeleteRequest>
    {
        public ServiceController(IServiceService service) 
            : base(service)
        {
        } 
    }
}
