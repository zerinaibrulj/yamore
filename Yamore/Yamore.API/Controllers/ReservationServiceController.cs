using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.ReservationService;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ReservationServiceController : BaseCRUDController<Model.ReservationService, ReservationServiceSearchObject, ReservationServiceInsertRequest, ReservationServiceUpdateRequest, ReservationServiceDeleteRequest>
    {
        public ReservationServiceController(IReservationServiceService service)
            : base(service)
        {
        }
    }
}
