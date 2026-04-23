using System.Globalization;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Stripe;
using Yamore.API.Configuration;
using Yamore.Model;
using Yamore.Model.Messages;
using Yamore.Model.Requests.Payment;
using Yamore.Model.Requests.Reservation;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;
using DbPayment = Yamore.Services.Database.Payment;

namespace Yamore.API.Services;

public class PaymentWorkflowService : IPaymentWorkflowService
{
    private readonly _220245Context _context;
    private readonly StripePaymentService _stripe;
    private readonly IConfiguration _configuration;
    private readonly IMessagePublisher _messagePublisher;
    private readonly IReservationService _reservationService;
    private readonly ILogger<PaymentWorkflowService> _logger;

    public PaymentWorkflowService(
        _220245Context context,
        StripePaymentService stripe,
        IConfiguration configuration,
        IMessagePublisher messagePublisher,
        IReservationService reservationService,
        ILogger<PaymentWorkflowService> logger)
    {
        _context = context;
        _stripe = stripe;
        _configuration = configuration;
        _messagePublisher = messagePublisher;
        _reservationService = reservationService;
        _logger = logger;
    }

    public string GetStripePublishableKey()
        => StripeKeyResolver.GetPublishableKey(_configuration) ?? "";

    public async Task<PaymentIntentDto> PrepareProvisionalCardBookingAsync(
        PrepareCardBookingRequest request,
        int claimUserId,
        CancellationToken cancellationToken)
    {
        if (claimUserId != request.UserId)
            throw new UnauthorizedAccessException("The booking user must match the signed-in account.");

        if (!_stripe.IsConfigured)
            throw new Exception("Stripe is not configured.");

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
            return new PaymentIntentDto
            {
                ClientSecret = clientSecret,
                PaymentIntentId = paymentIntentId,
                Status = "requires_payment_method",
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Stripe CreateProvisionalBookingIntentAsync failed.");
            throw new InvalidOperationException("Unable to start payment. Please try again later.");
        }
    }

    public async Task<PaymentIntentDto> CreateIntentForExistingReservationAsync(
        CreatePaymentIntentRequest request,
        CancellationToken cancellationToken)
    {
        var reservation = await _context.Reservations.FindAsync(new object[] { request.ReservationId }, cancellationToken);
        if (reservation == null)
            throw new KeyNotFoundException("Reservation not found.");
        if (string.Equals(reservation.Status, ReservationStatuses.Cancelled, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Reservation is cancelled.");

        var method = (request.PaymentMethod ?? "stripe").ToLowerInvariant();
        if (method != "stripe" && method != "card")
            throw new InvalidOperationException("Create intent is only for card (Stripe) payments.");

        if (!_stripe.IsConfigured)
            throw new Exception("Stripe is not configured.");

        var amount = request.Amount > 0 ? request.Amount : (reservation.TotalPrice ?? 0);
        if (amount <= 0)
            throw new InvalidOperationException("Reservation has no amount to charge.");

        try
        {
            var (clientSecret, paymentIntentId) = await _stripe.CreatePaymentIntentAsync(
                request.ReservationId,
                amount,
                "eur",
                cancellationToken);

            return new PaymentIntentDto
            {
                ClientSecret = clientSecret,
                PaymentIntentId = paymentIntentId,
                Status = "requires_payment_method",
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Stripe CreatePaymentIntentAsync failed for reservation {ReservationId}.", request.ReservationId);
            throw new InvalidOperationException("Unable to create payment. Please try again later.");
        }
    }

    public async Task<PaymentIntentDto> ConfirmPaymentAsync(
        ConfirmPaymentRequest request,
        int? currentUserId,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.PaymentIntentId))
        {
            if (request.ReservationId <= 0)
                throw new InvalidOperationException("Reservation is required for offline payment.");

            var resOffline = await _context.Reservations.FindAsync(new object[] { request.ReservationId }, cancellationToken);
            if (resOffline == null)
                throw new KeyNotFoundException("Reservation not found.");
            if (string.Equals(resOffline.Status, ReservationStatuses.Cancelled, StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Reservation is cancelled.");

            var paymentMethod = string.IsNullOrWhiteSpace(request.PaymentMethod)
                ? "Cash"
                : request.PaymentMethod.Trim();
            if (paymentMethod.Length > 20)
                paymentMethod = paymentMethod.Substring(0, 20);
            const string status = "pending";

            var pay = new DbPayment
            {
                ReservationId = request.ReservationId,
                Amount = resOffline.TotalPrice ?? 0,
                PaymentDate = DateTime.UtcNow,
                PaymentMethod = paymentMethod,
                Status = status
            };
            _context.Payments.Add(pay);
            await _context.SaveChangesAsync(cancellationToken);

            PublishPaymentCompleted(pay, paymentMethod, status, isConfirmed: false);
            return new PaymentIntentDto { Status = status };
        }

        if (!_stripe.IsConfigured)
            throw new Exception("Stripe is not configured.");

        var intent = await _stripe.GetPaymentIntentAsync(request.PaymentIntentId, cancellationToken);
        if (intent.Status != "succeeded")
            throw new InvalidOperationException("Payment has not been completed or could not be verified.");

        var meta = intent.Metadata?.ToDictionary(x => x.Key, x => x.Value) ?? new Dictionary<string, string>();

        if (meta.TryGetValue("FulfilledReservationId", out var fu)
            && int.TryParse(fu, out var existingRid)
            && existingRid > 0)
        {
            return new PaymentIntentDto { Status = "pending", PaymentIntentId = request.PaymentIntentId };
        }

        if (meta.TryGetValue("Kind", out var kind)
            && string.Equals(kind, "provisional_booking", StringComparison.Ordinal)
            && request.ReservationId == 0)
        {
            return await ConfirmProvisionalCardBookingAsync(
                request.PaymentIntentId!, intent, meta, currentUserId, cancellationToken);
        }

        if (request.ReservationId <= 0)
            throw new InvalidOperationException("Reservation id is required for this payment, or use the new card flow with reservationId 0.");

        if (!meta.TryGetValue("ReservationId", out var resMeta)
            || !int.TryParse(resMeta, out var resFromMeta)
            || resFromMeta != request.ReservationId)
            throw new InvalidOperationException("Payment does not match this reservation.");

        return await ConfirmCardForExistingReservationAsync(request, currentUserId, cancellationToken);
    }

    private async Task<PaymentIntentDto> ConfirmProvisionalCardBookingAsync(
        string paymentIntentId,
        PaymentIntent intent,
        IReadOnlyDictionary<string, string> meta,
        int? currentUserId,
        CancellationToken cancellationToken)
    {
        if (!meta.TryGetValue("UserId", out var userS) || !int.TryParse(userS, out var metaUserId))
            throw new InvalidOperationException("Invalid payment metadata (user).");
        if (!meta.TryGetValue("YachtId", out var yachtS) || !int.TryParse(yachtS, out var yachtId))
            throw new InvalidOperationException("Invalid payment metadata (yacht).");
        if (!meta.TryGetValue("StartUtc", out var startS) || !meta.TryGetValue("EndUtc", out var endS))
            throw new InvalidOperationException("Invalid payment metadata (dates).");

        if (currentUserId is not { } uid || uid != metaUserId)
            throw new UnauthorizedAccessException("The payment user must match the signed-in account.");

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
            throw new InvalidOperationException("Payment amount does not match the booking. Please start checkout again.");

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
        var paymentEntity = new DbPayment
        {
            ReservationId = reservation.ReservationId,
            Amount = total,
            PaymentDate = DateTime.UtcNow,
            PaymentMethod = "Card",
            Status = payStatus
        };
        _context.Payments.Add(paymentEntity);
        await _context.SaveChangesAsync(cancellationToken);

        try
        {
            await _stripe.TagPaymentIntentFulfilledAsync(paymentIntentId, reservation.ReservationId, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Stripe TagPaymentIntentFulfilledAsync failed for PaymentIntent {PaymentIntentId}.", paymentIntentId);
        }

        var msgCtx = _reservationService.GetReservationMessageContext(reservation.UserId, yachtId);
        var resMsg = new ReservationCreatedMessage
        {
            ReservationId = reservation.ReservationId,
            UserId = reservation.UserId,
            YachtId = reservation.YachtId,
            YachtName = msgCtx.YachtName,
            StartDate = reservation.StartDate,
            EndDate = reservation.EndDate,
            TotalPrice = total,
            UserEmail = msgCtx.UserEmail,
            UserName = msgCtx.UserDisplayName,
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
            UserEmail = msgCtx.UserEmail,
            UserName = msgCtx.UserDisplayName,
            YachtName = msgCtx.YachtName,
            ReservationStartDate = reservation.StartDate,
            ReservationEndDate = reservation.EndDate,
        };
        _messagePublisher.Publish(MessageEnvelope.PaymentCompleted, JsonSerializer.Serialize(payMsg));

        return new PaymentIntentDto { Status = payStatus, PaymentIntentId = paymentIntentId };
    }

    private async Task<PaymentIntentDto> ConfirmCardForExistingReservationAsync(
        ConfirmPaymentRequest request,
        int? currentUserId,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.PaymentIntentId))
            throw new InvalidOperationException("Payment intent is required.");

        if (!_stripe.IsConfigured)
            throw new Exception("Stripe is not configured.");
        var succeeded = await _stripe.PaymentSucceededAsync(request.PaymentIntentId, cancellationToken);
        if (!succeeded)
            throw new InvalidOperationException("Payment has not been completed or could not be verified.");

        var reservation = await _context.Reservations.FindAsync(new object[] { request.ReservationId }, cancellationToken);
        if (reservation == null)
            throw new KeyNotFoundException("Reservation not found.");
        if (string.Equals(reservation.Status, ReservationStatuses.Cancelled, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Reservation is cancelled.");

        const string paymentMethod = "Card";
        const string status = "pending";
        _reservationService.ConfirmFromSuccessfulCardPayment(request.ReservationId, currentUserId);
        await _context.Entry(reservation).ReloadAsync(cancellationToken);

        var payCard = new DbPayment
        {
            ReservationId = request.ReservationId,
            Amount = reservation.TotalPrice ?? 0,
            PaymentDate = DateTime.UtcNow,
            PaymentMethod = paymentMethod,
            Status = status
        };
        _context.Payments.Add(payCard);
        await _context.SaveChangesAsync(cancellationToken);
        var msgCtx = _reservationService.GetReservationMessageContext(reservation.UserId, reservation.YachtId);

        var payMsg = new PaymentCompletedMessage
        {
            PaymentId = payCard.PaymentId,
            ReservationId = payCard.ReservationId,
            Amount = payCard.Amount,
            PaymentMethod = paymentMethod,
            PaymentStatus = status,
            IsConfirmed = true,
            UserEmail = msgCtx.UserEmail,
            UserName = msgCtx.UserDisplayName,
            YachtName = msgCtx.YachtName,
            ReservationStartDate = reservation.StartDate,
            ReservationEndDate = reservation.EndDate,
        };
        _messagePublisher.Publish(MessageEnvelope.PaymentCompleted, JsonSerializer.Serialize(payMsg));

        return new PaymentIntentDto { Status = status };
    }

    private void PublishPaymentCompleted(
        DbPayment payment,
        string paymentMethod,
        string status,
        bool isConfirmed)
    {
        var res = _context.Reservations.Find(payment.ReservationId);
        var msgCtx = res == null
            ? null
            : _reservationService.GetReservationMessageContext(res.UserId, res.YachtId);
        var msg = new PaymentCompletedMessage
        {
            PaymentId = payment.PaymentId,
            ReservationId = payment.ReservationId,
            Amount = payment.Amount,
            PaymentMethod = paymentMethod,
            PaymentStatus = status,
            IsConfirmed = isConfirmed,
            UserEmail = msgCtx?.UserEmail,
            UserName = msgCtx?.UserDisplayName,
            YachtName = msgCtx?.YachtName,
            ReservationStartDate = res?.StartDate,
            ReservationEndDate = res?.EndDate,
        };
        _messagePublisher.Publish(MessageEnvelope.PaymentCompleted, JsonSerializer.Serialize(msg));
    }
}
