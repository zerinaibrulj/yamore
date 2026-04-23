using System.Globalization;
using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Stripe;
using Yamore.API.Configuration;
using Yamore.API.Services;
using Yamore.Model;
using Yamore.Model.Messages;
using Yamore.Model.Requests.Payment;
using Yamore.Model.Requests.Reservation;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

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
        private readonly IReservationService _reservationService;

        public PaymentController(
            _220245Context context,
            StripePaymentService stripe,
            IConfiguration configuration,
            IMessagePublisher messagePublisher,
            IReservationService reservationService)
        {
            _context = context;
            _stripe = stripe;
            _configuration = configuration;
            _messagePublisher = messagePublisher;
            _reservationService = reservationService;
        }

        /// <summary>
        /// Returns Stripe publishable key for client-side SDK (e.g. Flutter). No auth required so the app can init Stripe before login if needed.
        /// </summary>
        [HttpGet("stripe-config")]
        [AllowAnonymous]
        public ActionResult<object> GetStripeConfig()
        {
            var publishableKey = StripeKeyResolver.GetPublishableKey(_configuration) ?? "";
            return Ok(new { PublishableKey = publishableKey });
        }

        /// <summary>Creates a Stripe PaymentIntent for a <b>new</b> booking without writing a reservation row. Confirm with <c>POST confirm</c> and <c>reservationId: 0</c> after the client payment succeeds.</summary>
        [HttpPost("prepare-card-booking")]
        public async Task<ActionResult<PaymentIntentDto>> PrepareCardBooking(
            [FromBody] PrepareCardBookingRequest request,
            CancellationToken cancellationToken)
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdStr, out var claimUserId) || claimUserId != request.UserId)
                return Unauthorized("The booking user must match the signed-in account.");

            if (!_stripe.IsConfigured)
                return StatusCode(500, "Stripe is not configured. Set Stripe:SecretKey and Stripe:PublishableKey.");

            var serviceIds = request.ServiceIds ?? new List<int>();
            var total = _reservationService.ValidateAndQuoteCardBooking(
                request.YachtId, request.StartDate, request.EndDate, serviceIds);

            var metadata = new Dictionary<string, string>
            {
                ["Kind"] = "provisional_booking",
                ["UserId"] = request.UserId.ToString(CultureInfo.InvariantCulture),
                ["YachtId"] = request.YachtId.ToString(CultureInfo.InvariantCulture),
                ["StartUtc"] = request.StartDate.ToUniversalTime().ToString("o", CultureInfo.InvariantCulture),
                ["EndUtc"] = request.EndDate.ToUniversalTime().ToString("o", CultureInfo.InvariantCulture),
                ["ServiceIds"] = string.Join(",", serviceIds),
            };

            try
            {
                var (clientSecret, paymentIntentId) = await _stripe.CreateProvisionalBookingIntentAsync(
                    metadata, total, "eur", cancellationToken);
                return Ok(new PaymentIntentDto
                {
                    ClientSecret = clientSecret,
                    PaymentIntentId = paymentIntentId,
                    Status = "requires_payment_method",
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = "Stripe error", message = ex.Message });
            }
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
                    Status = "requires_payment_method",
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
            // Offline (cash / bank) — existing reservation only
            if (string.IsNullOrWhiteSpace(request.PaymentIntentId))
            {
                if (request.ReservationId <= 0)
                    return BadRequest("Reservation is required for offline payment.");

                var reservation = _context.Reservations.Find(request.ReservationId);
                if (reservation == null)
                    return NotFound("Reservation not found.");
                if (reservation.Status == "Cancelled")
                    return BadRequest("Reservation is cancelled.");

                var paymentMethod = string.IsNullOrWhiteSpace(request.PaymentMethod)
                    ? "Cash"
                    : request.PaymentMethod.Trim();
                if (paymentMethod.Length > 20)
                    paymentMethod = paymentMethod.Substring(0, 20);
                const string status = "pending";

                var pay = new Yamore.Services.Database.Payment
                {
                    ReservationId = request.ReservationId,
                    Amount = reservation.TotalPrice ?? 0,
                    PaymentDate = DateTime.UtcNow,
                    PaymentMethod = paymentMethod,
                    Status = status
                };
                _context.Payments.Add(pay);
                _context.SaveChanges();

                PublishPaymentCompleted(pay, paymentMethod, status, isConfirmed: false);
                return Ok(new PaymentIntentDto { Status = status });
            }

            if (!_stripe.IsConfigured)
                return StatusCode(500, "Stripe is not configured.");

            var intent = await _stripe.GetPaymentIntentAsync(request.PaymentIntentId, cancellationToken);
            if (intent.Status != "succeeded")
                return BadRequest("Payment has not been completed or could not be verified.");

            var meta = intent.Metadata?.ToDictionary(x => x.Key, x => x.Value) ?? new Dictionary<string, string>();

            if (meta.TryGetValue("FulfilledReservationId", out var fu)
                && int.TryParse(fu, out var existingRid)
                && existingRid > 0)
            {
                return Ok(new PaymentIntentDto { Status = "pending", PaymentIntentId = request.PaymentIntentId });
            }

            if (meta.TryGetValue("Kind", out var kind)
                && string.Equals(kind, "provisional_booking", StringComparison.Ordinal)
                && request.ReservationId == 0)
            {
                return await ConfirmProvisionalCardBookingAsync(request.PaymentIntentId!, intent, meta, cancellationToken);
            }

            if (request.ReservationId <= 0)
                return BadRequest("Reservation id is required for this payment, or use the new card flow with reservationId 0.");

            if (!meta.TryGetValue("ReservationId", out var resMeta)
                || !int.TryParse(resMeta, out var resFromMeta)
                || resFromMeta != request.ReservationId)
                return BadRequest("Payment does not match this reservation.");

            return await ConfirmCardForExistingReservationAsync(request, cancellationToken);
        }

        private async Task<ActionResult<PaymentIntentDto>> ConfirmProvisionalCardBookingAsync(
            string paymentIntentId,
            PaymentIntent intent,
            IReadOnlyDictionary<string, string> meta,
            CancellationToken cancellationToken)
        {
            if (!meta.TryGetValue("UserId", out var userS) || !int.TryParse(userS, out var metaUserId))
                return BadRequest("Invalid payment metadata (user).");
            if (!meta.TryGetValue("YachtId", out var yachtS) || !int.TryParse(yachtS, out var yachtId))
                return BadRequest("Invalid payment metadata (yacht).");
            if (!meta.TryGetValue("StartUtc", out var startS) || !meta.TryGetValue("EndUtc", out var endS))
                return BadRequest("Invalid payment metadata (dates).");

            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdStr, out var claimUserId) || claimUserId != metaUserId)
                return Unauthorized("The payment user must match the signed-in account.");

            var start = DateTime.Parse(startS, null, DateTimeStyles.RoundtripKind);
            var end = DateTime.Parse(endS, null, DateTimeStyles.RoundtripKind);

            var serviceIds = new List<int>();
            if (meta.TryGetValue("ServiceIds", out var svc) && !string.IsNullOrWhiteSpace(svc))
            {
                foreach (var p in svc.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
                {
                    if (int.TryParse(p, out var id))
                        serviceIds.Add(id);
                }
            }

            var total = _reservationService.ValidateAndQuoteCardBooking(yachtId, start, end, serviceIds);
            var expectedCents = (long)Math.Max(50, Math.Round(total * 100));
            if (intent.Amount != expectedCents)
                return BadRequest("Payment amount does not match the booking. Please start checkout again.");

            var insert = new ReservationInsertRequest
            {
                UserId = metaUserId,
                YachtId = yachtId,
                StartDate = start,
                EndDate = end,
                TotalPrice = total,
                Status = "Confirmed",
                CreatedAt = DateTime.UtcNow
            };

            var reservation = _reservationService.InsertConfirmedReservationWithServices(insert, serviceIds);

            const string payStatus = "pending";
            var paymentEntity = new Yamore.Services.Database.Payment
            {
                ReservationId = reservation.ReservationId,
                Amount = total,
                PaymentDate = DateTime.UtcNow,
                PaymentMethod = "Card",
                Status = payStatus
            };
            _context.Payments.Add(paymentEntity);
            _context.SaveChanges();

            await _stripe.TagPaymentIntentFulfilledAsync(paymentIntentId, reservation.ReservationId, cancellationToken);

            var user = _context.Users.Find(reservation.UserId);
            var yacht = _context.Yachts.Find(yachtId);
            var resMsg = new ReservationCreatedMessage
            {
                ReservationId = reservation.ReservationId,
                UserId = reservation.UserId,
                YachtId = reservation.YachtId,
                YachtName = yacht?.Name,
                StartDate = reservation.StartDate,
                EndDate = reservation.EndDate,
                TotalPrice = total,
                UserEmail = user?.Email,
                UserName = user == null ? null : $"{user.FirstName} {user.LastName}".Trim(),
            };
            _messagePublisher.Publish(MessageEnvelope.ReservationCreated, JsonSerializer.Serialize(resMsg));

            var payMsg = new PaymentCompletedMessage
            {
                PaymentId = paymentEntity.PaymentId,
                ReservationId = paymentEntity.ReservationId,
                Amount = paymentEntity.Amount,
                PaymentMethod = "Card",
                PaymentStatus = payStatus,
                IsConfirmed = true,
                UserEmail = user?.Email,
                UserName = user == null ? null : $"{user.FirstName} {user.LastName}".Trim(),
                YachtName = yacht?.Name,
                ReservationStartDate = reservation.StartDate,
                ReservationEndDate = reservation.EndDate,
            };
            _messagePublisher.Publish(MessageEnvelope.PaymentCompleted, JsonSerializer.Serialize(payMsg));

            return Ok(new PaymentIntentDto { Status = payStatus, PaymentIntentId = paymentIntentId });
        }

        private async Task<ActionResult<PaymentIntentDto>> ConfirmCardForExistingReservationAsync(
            ConfirmPaymentRequest request,
            CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(request.PaymentIntentId))
                return BadRequest("Payment intent is required.");

            if (!_stripe.IsConfigured)
                return StatusCode(500, "Stripe is not configured.");
            var succeeded = await _stripe.PaymentSucceededAsync(request.PaymentIntentId, cancellationToken);
            if (!succeeded)
                return BadRequest("Payment has not been completed or could not be verified.");

            var reservation = _context.Reservations.Find(request.ReservationId);
            if (reservation == null)
                return NotFound("Reservation not found.");
            if (reservation.Status == "Cancelled")
                return BadRequest("Reservation is cancelled.");

            const string paymentMethod = "Card";
            // DB CHECK: existing flow keeps "pending" (see previous implementation).
            const string status = "pending";
            reservation.Status = "Confirmed";

            var payCard = new Yamore.Services.Database.Payment
            {
                ReservationId = request.ReservationId,
                Amount = reservation.TotalPrice ?? 0,
                PaymentDate = DateTime.UtcNow,
                PaymentMethod = paymentMethod,
                Status = status
            };
            _context.Payments.Add(payCard);
            _context.SaveChanges();
            var resUser = _context.Users.Find(reservation.UserId);
            var y = _context.Yachts.Find(reservation.YachtId);

            var payMsg = new PaymentCompletedMessage
            {
                PaymentId = payCard.PaymentId,
                ReservationId = payCard.ReservationId,
                Amount = payCard.Amount,
                PaymentMethod = paymentMethod,
                PaymentStatus = status,
                IsConfirmed = true,
                UserEmail = resUser?.Email,
                UserName = resUser == null ? null : $"{resUser.FirstName} {resUser.LastName}".Trim(),
                YachtName = y?.Name,
                ReservationStartDate = reservation.StartDate,
                ReservationEndDate = reservation.EndDate,
            };
            _messagePublisher.Publish(MessageEnvelope.PaymentCompleted, JsonSerializer.Serialize(payMsg));

            return Ok(new PaymentIntentDto { Status = status });
        }

        private void PublishPaymentCompleted(
            Yamore.Services.Database.Payment payment,
            string paymentMethod,
            string status,
            bool isConfirmed)
        {
            var res = _context.Reservations.Find(payment.ReservationId);
            var u = res != null ? _context.Users.Find(res.UserId) : null;
            var y = res != null ? _context.Yachts.Find(res.YachtId) : null;
            var msg = new PaymentCompletedMessage
            {
                PaymentId = payment.PaymentId,
                ReservationId = payment.ReservationId,
                Amount = payment.Amount,
                PaymentMethod = paymentMethod,
                PaymentStatus = status,
                IsConfirmed = isConfirmed,
                UserEmail = u?.Email,
                UserName = u == null ? null : $"{u.FirstName} {u.LastName}".Trim(),
                YachtName = y?.Name,
                ReservationStartDate = res?.StartDate,
                ReservationEndDate = res?.EndDate,
            };
            _messagePublisher.Publish(MessageEnvelope.PaymentCompleted, JsonSerializer.Serialize(msg));
        }
    }
}
