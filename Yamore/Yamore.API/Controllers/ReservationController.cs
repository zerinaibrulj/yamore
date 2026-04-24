using System.Security.Claims;
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
            var ctx = _reservationService.GetReservationMessageContext(result.UserId, result.YachtId);
            var msg = new ReservationCreatedMessage
            {
                ReservationId = result.ReservationId,
                UserId = result.UserId,
                YachtId = result.YachtId,
                YachtName = ctx.YachtName,
                StartDate = result.StartDate,
                EndDate = result.EndDate,
                TotalPrice = result.TotalPrice,
                UserEmail = ctx.UserEmail,
                UserName = ctx.UserDisplayName,
            };
            _messagePublisher.Publish(MessageEnvelope.ReservationCreated, JsonSerializer.Serialize(msg));
            Response.Headers["X-Operation-Message"] = "Reservation created successfully.";
            return Ok(result);
        }

        [HttpDelete("{id}")]
        public override ActionResult<Model.Reservation> Delete(int id) =>
            RejectWithUserError("Reservations cannot be deleted. Use cancel instead.");

        [HttpPut("{id}/cancel")]
        [Authorize]
        public ActionResult<Model.Reservation> Cancel(int id, [FromBody] CancelReservationRequest? body)
        {
            if (!int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var actorId))
                return Unauthorized();

            var isAdmin = User.IsInRole(AppRoles.Admin);
            var outcome = _reservationService.Cancel(id, actorId, isAdmin, body?.Reason);
            Response.Headers["X-Operation-Message"] = "Reservation cancelled.";
            Response.Headers["X-Reservation-Cancel-Has-Card-Payment"] = outcome.HadCardPayment ? "true" : "false";
            return Ok(outcome.Reservation);
        }

        [HttpPut("{id}/reject")]
        [Authorize(Roles = AppRoles.Admin)]
        public ActionResult<Model.Reservation> Reject(int id, [FromBody] RejectReservationRequest body)
        {
            if (!int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var adminId))
                return Unauthorized();

            var result = _reservationService.Reject(id, adminId, body.Reason);
            Response.Headers["X-Operation-Message"] = "Reservation rejected.";
            return Ok(result);
        }

        [HttpPut("{id}/complete")]
        [Authorize]
        public ActionResult<Model.Reservation> Complete(int id)
        {
            if (!int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var actorId))
                return Unauthorized();

            var isAdmin = User.IsInRole(AppRoles.Admin);
            var result = _reservationService.Complete(id, actorId, isAdmin);
            Response.Headers["X-Operation-Message"] = "Reservation marked completed.";
            return Ok(result);
        }

        [HttpPut("{id}/confirm")]
        [Authorize(Roles = AppRoles.AdminYachtOwner)]
        public ActionResult<Model.Reservation> Confirm(int id)
        {
            if (!int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var actorId))
                return Unauthorized();

            var isAdmin = User.IsInRole(AppRoles.Admin);
            var isYachtOwner = User.IsInRole(AppRoles.YachtOwner);
            var result = _reservationService.Confirm(id, actorId, isAdmin, isYachtOwner);
            Response.Headers["X-Operation-Message"] = "Reservation confirmed.";
            return Ok(result);
        }
    }
}
