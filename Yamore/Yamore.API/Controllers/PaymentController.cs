using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.API.Services;
using Yamore.Model;
using Yamore.Model.Messages;
using Yamore.Services.Database;

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
        private readonly _220245Context _context;
        private readonly StripePaymentService _stripe;
        private readonly IConfiguration _configuration;
        private readonly IMessagePublisher _messagePublisher;

        public PaymentController(
            _220245Context context,
            StripePaymentService stripe,
            IConfiguration configuration,
            IMessagePublisher messagePublisher)
        {
            _context = context;
            _stripe = stripe;
            _configuration = configuration;
            _messagePublisher = messagePublisher;
        }

        /// <summary>
        /// Returns Stripe publishable key for client-side SDK (e.g. Flutter). No auth required so the app can init Stripe before login if needed.
        /// </summary>
        [HttpGet("stripe-config")]
        [AllowAnonymous]
        public ActionResult<object> GetStripeConfig()
        {
            var publishableKey = _configuration["Stripe:PublishableKey"];
            return Ok(new { PublishableKey = publishableKey ?? "" });
        }

        [HttpPost("create-intent")]
        public async Task<ActionResult<PaymentIntentDto>> CreateIntent(
            [FromBody] CreatePaymentIntentRequest request,
            CancellationToken cancellationToken)
        {
            var reservation = _context.Reservations.Find(request.ReservationId);
            if (reservation == null)
                return NotFound("Reservation not found.");
            if (reservation.Status == "Cancelled")
                return BadRequest("Reservation is cancelled.");

            var method = (request.PaymentMethod ?? "stripe").ToLowerInvariant();
            if (method != "stripe" && method != "card")
                return BadRequest("Create intent is only for card (Stripe) payments. Use confirm with PaymentMethod for cash/bank transfer.");

            if (!_stripe.IsConfigured)
                return StatusCode(500, "Stripe is not configured. Set Stripe:SecretKey and Stripe:PublishableKey.");

            var amount = request.Amount > 0 ? request.Amount : (reservation.TotalPrice ?? 0);
            if (amount <= 0)
                return BadRequest("Reservation has no amount to charge.");

            try
            {
                var (clientSecret, paymentIntentId) = await _stripe.CreatePaymentIntentAsync(
                    request.ReservationId,
                    amount,
                    "eur",
                    cancellationToken);

                return Ok(new PaymentIntentDto
                {
                    ClientSecret = clientSecret,
                    PaymentIntentId = paymentIntentId,
                    Status = "requires_payment_method"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = "Stripe error", message = ex.Message });
            }
        }

        [HttpPost("confirm")]
        public async Task<ActionResult<PaymentIntentDto>> Confirm(
            [FromBody] ConfirmPaymentRequest request,
            CancellationToken cancellationToken)
        {
            var reservation = _context.Reservations.Find(request.ReservationId);
            if (reservation == null)
                return NotFound("Reservation not found.");
            if (reservation.Status == "Cancelled")
                return BadRequest("Reservation is cancelled.");

            string paymentMethod;
            string status;

            if (!string.IsNullOrWhiteSpace(request.PaymentIntentId))
            {
                // Card payment: verify with Stripe that payment succeeded
                if (!_stripe.IsConfigured)
                    return StatusCode(500, "Stripe is not configured.");
                var succeeded = await _stripe.PaymentSucceededAsync(request.PaymentIntentId, cancellationToken);
                if (!succeeded)
                    return BadRequest("Payment has not been completed or could not be verified.");
                paymentMethod = "Card";
                status = "succeeded";
            }
            else
            {
                // Offline: cash or bank transfer – record only
                paymentMethod = string.IsNullOrWhiteSpace(request.PaymentMethod)
                    ? "Cash"
                    : request.PaymentMethod.Trim();
                if (paymentMethod.Length > 20)
                    paymentMethod = paymentMethod.Substring(0, 20);
                status = "pending";
            }

            var payment = new Yamore.Services.Database.Payment
            {
                ReservationId = request.ReservationId,
                Amount = reservation.TotalPrice ?? 0,
                PaymentDate = DateTime.UtcNow,
                PaymentMethod = paymentMethod,
                Status = status
            };
            _context.Payments.Add(payment);

            if (status == "succeeded")
                reservation.Status = "Confirmed";

            _context.SaveChanges();

            var payMsg = new PaymentCompletedMessage
            {
                PaymentId = payment.PaymentId,
                ReservationId = payment.ReservationId,
                Amount = payment.Amount,
                PaymentMethod = paymentMethod,
            };
            _messagePublisher.Publish(MessageEnvelope.PaymentCompleted, JsonSerializer.Serialize(payMsg));

            return Ok(new PaymentIntentDto { Status = status });
        }
    }
}
