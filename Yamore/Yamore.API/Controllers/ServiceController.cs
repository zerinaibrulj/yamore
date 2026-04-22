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
        private readonly IServiceService _serviceService;

        public ServiceController(IServiceService service) 
            : base(service)
        {
            _serviceService = service;
        }

        [HttpDelete("{id}")]
        public override ActionResult<Model.Service> Delete(int id)
        {
            var err = _serviceService.GetDeleteBlockingErrorMessage(id);
            if (err != null) return RejectWithUserError(err);
            return base.Delete(id);
        }
    }
}
