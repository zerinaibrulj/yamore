using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    /// <summary>
    /// Payment endpoints – placeholders for Stripe/PayPal integration.
    /// Implement actual gateway calls (Stripe SDK, PayPal SDK) in a dedicated service and replace these stubs.
    /// </summary>
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class PaymentController : ControllerBase
    {
        private readonly _220245Context _context;

        public PaymentController(_220245Context context)
        {
            _context = context;
        }

        [HttpPost("create-intent")]
        public ActionResult<PaymentIntentDto> CreateIntent([FromBody] CreatePaymentIntentRequest request)
        {
            var reservation = _context.Reservations.Find(request.ReservationId);
            if (reservation == null)
                return NotFound("Reservation not found.");
            if (reservation.Status == "Cancelled")
                return BadRequest("Reservation is cancelled.");

            // TODO: Integrate Stripe PaymentIntent or PayPal order creation here.
            // Example Stripe: var service = new PaymentIntentService(); var intent = service.Create(...); return intent.ClientSecret;
            var dto = new PaymentIntentDto
            {
                ClientSecret = "placeholder_secret_" + request.ReservationId,
                PaymentIntentId = "pi_placeholder_" + request.ReservationId,
                RedirectUrl = request.PaymentMethod == "paypal" ? "https://paypal.com/checkout/placeholder" : null,
                Status = "requires_payment_method"
            };
            return Ok(dto);
        }

        [HttpPost("confirm")]
        public ActionResult<PaymentIntentDto> Confirm([FromBody] ConfirmPaymentRequest request)
        {
            var reservation = _context.Reservations.Find(request.ReservationId);
            if (reservation == null)
                return NotFound("Reservation not found.");

            // TODO: Confirm payment with Stripe/PayPal, then create Payment record and optionally update Reservation status.

            var payment = new Yamore.Services.Database.Payment
            {
                ReservationId = request.ReservationId,
                Amount = reservation.TotalPrice ?? 0,
                PaymentDate = DateTime.UtcNow,
                PaymentMethod = "card",
                Status = "succeeded"
            };
            _context.Payments.Add(payment);
            _context.SaveChanges();

            return Ok(new PaymentIntentDto { Status = "succeeded" });
        }
    }
}
