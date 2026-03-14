using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.API.Services;
using Yamore.Model;
using Yamore.Model.Messages;
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
        private readonly IMessagePublisher _messagePublisher;

        public ReservationController(IReservationService service, IMessagePublisher messagePublisher)
            : base(service)
        {
            _reservationService = service;
            _messagePublisher = messagePublisher;
        }

        [HttpPost]
        public override ActionResult<Model.Reservation> Insert(ReservationInsertRequest request)
        {
            var result = _reservationService.Insert(request);
            var msg = new ReservationCreatedMessage
            {
                ReservationId = result.ReservationId,
                UserId = result.UserId,
                YachtId = result.YachtId,
                StartDate = result.StartDate,
                EndDate = result.EndDate,
                TotalPrice = result.TotalPrice,
            };
            _messagePublisher.Publish(MessageEnvelope.ReservationCreated, JsonSerializer.Serialize(msg));
            Response.Headers["X-Operation-Message"] = "Reservation created successfully.";
            return Ok(result);
        }

        [HttpPut("{id}/cancel")]
        public ActionResult<Model.Reservation> Cancel(int id)
        {
            var result = _reservationService.Cancel(id);
            Response.Headers["X-Operation-Message"] = "Reservation cancelled.";
            return Ok(result);
        }

        [HttpPut("{id}/confirm")]
        [Authorize(Roles = "Admin,YachtOwner")]
        public ActionResult<Model.Reservation> Confirm(int id)
        {
            var result = _reservationService.Confirm(id);
            Response.Headers["X-Operation-Message"] = "Reservation confirmed.";
            return Ok(result);
        }
    }
}
