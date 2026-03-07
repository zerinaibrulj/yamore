using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.Reservation;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ReservationController : BaseCRUDController<Model.Reservation, ReservationSearchObject, ReservationInsertRequest, ReservationUpdateRequest, ReservationDeleteRequest>
    {
        private readonly IReservationService _reservationService;

        public ReservationController(IReservationService service)
            : base(service)
        {
            _reservationService = service;
        }

        [HttpPut("{id}/cancel")]
        public ActionResult<Model.Reservation> Cancel(int id)
        {
            var result = _reservationService.Cancel(id);
            Response.Headers["X-Operation-Message"] = "Reservation cancelled.";
            return Ok(result);
        }
    }
}
