using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.API.Services;
using Yamore.Model;
using Yamore.Model.Requests.Payment;
using Yamore.Model.Requests.Reservation;

namespace Yamore.API.Controllers
{
    /// <summary>
    /// Payment endpoints: Stripe for card payments, and offline (cash/bank transfer) recording.
    /// </summary>
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class PaymentController : ControllerBase
    {
        private readonly IPaymentWorkflowService _paymentWorkflow;

        public PaymentController(IPaymentWorkflowService paymentWorkflow)
        {
            _paymentWorkflow = paymentWorkflow;
        }

        /// <summary>
        /// Returns Stripe publishable key for client-side SDK (e.g. Flutter). No auth required so the app can init Stripe before login if needed.
        /// </summary>
        [HttpGet("stripe-config")]
        [AllowAnonymous]
        public ActionResult<object> GetStripeConfig()
        {
            return Ok(new { PublishableKey = _paymentWorkflow.GetStripePublishableKey() });
        }

        /// <summary>Creates a Stripe PaymentIntent for a <b>new</b> booking without writing a reservation row.</summary>
        [HttpPost("prepare-card-booking")]
        public async Task<ActionResult<PaymentIntentDto>> PrepareCardBooking(
            [FromBody] PrepareCardBookingRequest request,
            CancellationToken cancellationToken)
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdStr, out var claimUserId))
                return Unauthorized();

            var result = await _paymentWorkflow.PrepareProvisionalCardBookingAsync(
                request, claimUserId, cancellationToken);
            return Ok(result);
        }

        [HttpPost("create-intent")]
        public async Task<ActionResult<PaymentIntentDto>> CreateIntent(
            [FromBody] CreatePaymentIntentRequest request,
            CancellationToken cancellationToken)
        {
            var result = await _paymentWorkflow.CreateIntentForExistingReservationAsync(request, cancellationToken);
            return Ok(result);
        }

        [HttpPost("confirm")]
        public async Task<ActionResult<PaymentIntentDto>> Confirm(
            [FromBody] ConfirmPaymentRequest request,
            CancellationToken cancellationToken)
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            int? currentUserId = int.TryParse(userIdStr, out var uid) ? uid : null;

            var result = await _paymentWorkflow.ConfirmPaymentAsync(request, currentUserId, cancellationToken);
            return Ok(result);
        }
    }
}
