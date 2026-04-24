using System.Data;
using System.Globalization;
using System.Text.Json;
using System.Text.Json.Nodes;
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
using DbReservation = Yamore.Services.Database.Reservation;

namespace Yamore.API.Services;

public class PaymentWorkflowService : IPaymentWorkflowService
{
    private const string StripePaymentIntentSucceeded = "payment_intent.succeeded";

    private readonly _220245Context _context;
    private readonly StripePaymentService _stripe;
    private readonly IConfiguration _configuration;
    private readonly IMessagePublisher _messagePublisher;
    private readonly IReservationService _reservationService;
    private readonly INotificationService _notifications;
    private readonly ILogger<PaymentWorkflowService> _logger;

    public PaymentWorkflowService(
        _220245Context context,
        StripePaymentService stripe,
        IConfiguration configuration,
        IMessagePublisher messagePublisher,
        IReservationService reservationService,
        INotificationService notifications,
        ILogger<PaymentWorkflowService> logger)
    {
        _context = context;
        _stripe = stripe;
        _configuration = configuration;
        _messagePublisher = messagePublisher;
        _reservationService = reservationService;
        _notifications = notifications;
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
            throw new BusinessException("Stripe is not configured.");

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
        int currentUserId,
        bool isAdmin,
        bool isYachtOwner,
        CancellationToken cancellationToken)
    {
        var reservation = await _context.Reservations.FindAsync(new object[] { request.ReservationId }, cancellationToken);
        if (reservation == null)
            throw new NotFoundException("Reservation not found.");
        if (string.Equals(reservation.Status, ReservationStatuses.Cancelled, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Reservation is cancelled.");

        EnsureCanPayForReservation(reservation, currentUserId, isAdmin, isYachtOwner, cancellationToken);

        var method = (request.PaymentMethod ?? "stripe").ToLowerInvariant();
        if (method != "stripe" && method != "card")
            throw new InvalidOperationException("Create intent is only for card (Stripe) payments.");

        if (!_stripe.IsConfigured)
            throw new BusinessException("Stripe is not configured.");

        if (!string.Equals(reservation.Status, ReservationStatuses.Pending, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Only pending reservations can be paid for online.");

        if (HasAnyPositivePayment(request.ReservationId))
            throw new InvalidOperationException("A payment is already recorded for this reservation.");

        var amount = reservation.TotalPrice ?? 0;
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
        bool isAdmin,
        bool isYachtOwner,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.PaymentIntentId))
        {
            if (request.ReservationId <= 0)
                throw new InvalidOperationException("Reservation is required for offline payment.");
            if (currentUserId is not { } uid)
                throw new UnauthorizedAccessException("You must be signed in.");

            var resOffline = await _context.Reservations.FindAsync(new object[] { request.ReservationId }, cancellationToken);
            if (resOffline == null)
                throw new NotFoundException("Reservation not found.");
            if (string.Equals(resOffline.Status, ReservationStatuses.Cancelled, StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Reservation is cancelled.");

            EnsureCanPayForReservation(resOffline, uid, isAdmin, isYachtOwner, cancellationToken);

            if (HasAnyPositivePayment(request.ReservationId))
                throw new InvalidOperationException("A payment is already recorded for this reservation.");

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
            throw new BusinessException("Stripe is not configured.");

        var intent = await _stripe.GetPaymentIntentAsync(request.PaymentIntentId, cancellationToken);
        if (intent.Status != "succeeded")
            throw new InvalidOperationException("Payment has not been completed or could not be verified.");

        var meta = intent.Metadata?.ToDictionary(x => x.Key, x => x.Value) ?? new Dictionary<string, string>();

        if (meta.TryGetValue("FulfilledReservationId", out var fu)
            && int.TryParse(fu, out var existingRid)
            && existingRid > 0)
        {
            return new PaymentIntentDto
            {
                Status = "succeeded",
                PaymentIntentId = request.PaymentIntentId,
                AlreadyFinalized = true,
            };
        }

        if (meta.TryGetValue("Kind", out var kind)
            && string.Equals(kind, "provisional_booking", StringComparison.Ordinal)
            && request.ReservationId == 0)
        {
            if (currentUserId is not { } claimUid)
                throw new UnauthorizedAccessException("You must be signed in.");
            return await ConfirmProvisionalCardBookingAsync(
                request.PaymentIntentId!, intent, meta, claimUid, skipUserMatch: false, cancellationToken);
        }

        if (request.ReservationId <= 0)
            throw new InvalidOperationException("Reservation id is required for this payment, or use the new card flow with reservationId 0.");

        if (currentUserId is not { } cuid)
            throw new UnauthorizedAccessException("You must be signed in.");

        if (!meta.TryGetValue("ReservationId", out var resMeta)
            || !int.TryParse(resMeta, out var resFromMeta)
            || resFromMeta != request.ReservationId)
            throw new InvalidOperationException("Payment does not match this reservation.");

        return await ConfirmCardForExistingReservationAsync(
            request,
            intent,
            cuid,
            isAdmin,
            isYachtOwner,
            fromWebhook: false,
            cancellationToken);
    }

    public async Task<StripeWebhookHandleResult> ProcessStripeWebhookAsync(
        string json,
        string stripeSignatureHeader,
        CancellationToken cancellationToken)
    {
        var secret = StripeKeyResolver.GetWebhookSecret(_configuration);
        if (string.IsNullOrWhiteSpace(secret) || !secret.StartsWith("whsec_", StringComparison.Ordinal))
        {
            _logger.LogWarning("Stripe webhook received but Stripe:WebhookSecret is not set (or invalid).");
            return StripeWebhookHandleResult.NotConfigured;
        }

        if (string.IsNullOrWhiteSpace(stripeSignatureHeader))
        {
            _logger.LogWarning("Stripe webhook missing Stripe-Signature header.");
            throw new UnauthorizedAccessException("Missing Stripe-Signature header.");
        }

        Event stripeEvent;
        try
        {
            stripeEvent = EventUtility.ConstructEvent(json, stripeSignatureHeader, secret, throwOnApiVersionMismatch: false);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Stripe webhook signature verification failed.");
            throw new UnauthorizedAccessException("Invalid webhook signature.");
        }

        if (!string.Equals(stripeEvent.Type, StripePaymentIntentSucceeded, StringComparison.Ordinal))
            return StripeWebhookHandleResult.Skipped;

        if (!_stripe.IsConfigured)
            return StripeWebhookHandleResult.NotConfigured;

        string? paymentIntentId;
        if (stripeEvent.Data.Object is PaymentIntent pi)
            paymentIntentId = pi.Id;
        else
        {
            try
            {
                var idNode = JsonNode.Parse(json)?["data"]?["object"]?["id"];
                paymentIntentId = idNode?.ToString();
            }
            catch
            {
                paymentIntentId = null;
            }
        }

        if (string.IsNullOrEmpty(paymentIntentId))
        {
            _logger.LogWarning("Stripe webhook payment_intent.succeeded has no payment intent id.");
            return StripeWebhookHandleResult.Skipped;
        }

        var fullIntent = await _stripe.GetPaymentIntentAsync(paymentIntentId, cancellationToken);
        if (fullIntent.Status != "succeeded")
            return StripeWebhookHandleResult.Skipped;

        var meta = fullIntent.Metadata?.ToDictionary(x => x.Key, x => x.Value) ?? new Dictionary<string, string>();

        if (meta.TryGetValue("FulfilledReservationId", out var fuf)
            && int.TryParse(fuf, out var fufRid) && fufRid > 0)
        {
            return StripeWebhookHandleResult.Processed;
        }

        if (meta.TryGetValue("Kind", out var k) && string.Equals(k, "provisional_booking", StringComparison.Ordinal))
        {
            if (!meta.TryGetValue("UserId", out var userS) || !int.TryParse(userS, out var paidById))
            {
                _logger.LogWarning("Provisional webhook: missing user metadata.");
                return StripeWebhookHandleResult.Skipped;
            }

            await ConfirmProvisionalCardBookingAsync(
                paymentIntentId!,
                fullIntent,
                meta,
                paidById,
                skipUserMatch: true,
                cancellationToken);
            return StripeWebhookHandleResult.Processed;
        }

        if (meta.TryGetValue("ReservationId", out var ridS) && int.TryParse(ridS, out var rid) && rid > 0)
        {
            var req = new ConfirmPaymentRequest { PaymentIntentId = paymentIntentId, ReservationId = rid };
            await ConfirmCardForExistingReservationAsync(
                req,
                fullIntent,
                currentUserId: 0,
                isAdmin: false,
                isYachtOwner: false,
                fromWebhook: true,
                cancellationToken);
            return StripeWebhookHandleResult.Processed;
        }

        return StripeWebhookHandleResult.Skipped;
    }

    private async Task<PaymentIntentDto> ConfirmProvisionalCardBookingAsync(
        string paymentIntentId,
        PaymentIntent intent,
        IReadOnlyDictionary<string, string> meta,
        int currentOrPaidByUserId,
        bool skipUserMatch,
        CancellationToken cancellationToken)
    {
        if (!meta.TryGetValue("UserId", out var userS) || !int.TryParse(userS, out var metaUserId))
            throw new InvalidOperationException("Invalid payment metadata (user).");
        if (!meta.TryGetValue("YachtId", out var yachtS) || !int.TryParse(yachtS, out var yachtId))
            throw new InvalidOperationException("Invalid payment metadata (yacht).");
        if (!meta.TryGetValue("StartUtc", out var startS) || !meta.TryGetValue("EndUtc", out var endS))
            throw new InvalidOperationException("Invalid payment metadata (dates).");

        if (!skipUserMatch)
        {
            if (currentOrPaidByUserId != metaUserId)
                throw new UnauthorizedAccessException("The payment user must match the signed-in account.");
        }

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
        var expectedCents = StripePaymentService.GetChargeAmountInCents(total);
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

        const string payStatus = "pending";
        var pendingPay = new CardPaymentPendingInfo
        {
            Amount = total,
            PaymentMethod = "Card",
            Status = payStatus,
            PaymentDateUtc = DateTime.UtcNow,
        };
        var reservation = _reservationService.InsertConfirmedReservationWithServices(insert, serviceIds, pendingPay);
        var paymentEntity = await _context.Payments.AsNoTracking()
            .FirstOrDefaultAsync(p => p.ReservationId == reservation.ReservationId, cancellationToken);
        if (paymentEntity == null)
        {
            _logger.LogError(
                "No payment row for reservation {ReservationId} after InsertConfirmedReservationWithServices.",
                reservation.ReservationId);
        }

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
            PaymentId = paymentEntity?.PaymentId ?? 0,
            ReservationId = paymentEntity?.ReservationId ?? reservation.ReservationId,
            Amount = paymentEntity?.Amount ?? total,
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

        var y = await _context.Yachts.AsNoTracking().FirstOrDefaultAsync(x => x.YachtId == yachtId, cancellationToken);
        if (y != null)
        {
            var displayYacht = string.IsNullOrWhiteSpace(msgCtx.YachtName) ? "the yacht" : msgCtx.YachtName.Trim();
            var guestName = string.IsNullOrWhiteSpace(msgCtx.UserDisplayName) ? "A guest" : msgCtx.UserDisplayName.Trim();
            var p =
                $"{reservation.StartDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)} – {reservation.EndDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)}";
            _notifications.InsertUserNotification(
                reservation.UserId,
                "Payment received",
                $"Your card payment of {total:0.00} EUR was successful. {displayYacht} ({p}) is now confirmed.");
            _notifications.InsertUserNotification(
                y.OwnerId,
                "New paid booking",
                $"{guestName} completed payment. Booking for {displayYacht} ({p}) is confirmed.");
        }

        return new PaymentIntentDto { Status = payStatus, PaymentIntentId = paymentIntentId };
    }

    private async Task<PaymentIntentDto> ConfirmCardForExistingReservationAsync(
        ConfirmPaymentRequest request,
        PaymentIntent intent,
        int currentUserId,
        bool isAdmin,
        bool isYachtOwner,
        bool fromWebhook,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.PaymentIntentId))
            throw new InvalidOperationException("Payment intent is required.");

        if (!_stripe.IsConfigured)
            throw new BusinessException("Stripe is not configured.");

        if (intent.Status != "succeeded")
            throw new InvalidOperationException("Payment has not been completed or could not be verified.");

        var reservation = await _context.Reservations.FindAsync(new object[] { request.ReservationId }, cancellationToken);
        if (reservation == null)
            throw new NotFoundException("Reservation not found.");
        if (string.Equals(reservation.Status, ReservationStatuses.Cancelled, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Reservation is cancelled.");

        if (!fromWebhook)
        {
            EnsureCanPayForReservation(reservation, currentUserId, isAdmin, isYachtOwner, cancellationToken);
        }

        var total = reservation.TotalPrice ?? 0;
        var expectedCents = StripePaymentService.GetChargeAmountInCents(total);
        if (intent.Amount != expectedCents)
            throw new InvalidOperationException("Payment amount does not match the reservation total.");

        if (HasCardPaymentForReservation(request.ReservationId))
        {
            await _context.Entry(reservation).ReloadAsync(cancellationToken);
            return new PaymentIntentDto
            {
                Status = "succeeded",
                PaymentIntentId = request.PaymentIntentId,
                AlreadyFinalized = true,
            };
        }

        if (HasNonCardPayment(request.ReservationId))
            throw new InvalidOperationException("A non-card payment is already recorded for this reservation.");

        int? paidBy = fromWebhook ? null : currentUserId;
        const string paymentMethod = "Card";
        const string status = "pending";

        await using var transaction =
            await _context.Database.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken);
        try
        {
            _reservationService.ApplyCardPaymentConfirmation(reservation, paidBy);
            if (!HasCardPaymentForReservation(request.ReservationId))
            {
                _context.Payments.Add(new DbPayment
                {
                    ReservationId = request.ReservationId,
                    Amount = reservation.TotalPrice ?? 0,
                    PaymentDate = DateTime.UtcNow,
                    PaymentMethod = paymentMethod,
                    Status = status
                });
            }
            await _context.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
            await _context.Entry(reservation).ReloadAsync(cancellationToken);
            var payRow = await _context.Payments.AsNoTracking()
                .OrderByDescending(p => p.PaymentId)
                .FirstOrDefaultAsync(
                    p => p.ReservationId == request.ReservationId,
                    cancellationToken);
            var msgCtx = _reservationService.GetReservationMessageContext(reservation.UserId, reservation.YachtId);

            var payMsg2 = new PaymentCompletedMessage
            {
                PaymentId = payRow?.PaymentId ?? 0,
                ReservationId = payRow?.ReservationId ?? request.ReservationId,
                Amount = payRow?.Amount ?? (reservation.TotalPrice ?? 0),
                PaymentMethod = paymentMethod,
                PaymentStatus = status,
                IsConfirmed = true,
                UserEmail = msgCtx.UserEmail,
                UserName = msgCtx.UserDisplayName,
                YachtName = msgCtx.YachtName,
                ReservationStartDate = reservation.StartDate,
                ReservationEndDate = reservation.EndDate,
            };
            _messagePublisher.Publish(MessageEnvelope.PaymentCompleted, JsonSerializer.Serialize(payMsg2));

            var y2 = await _context.Yachts.AsNoTracking().FirstOrDefaultAsync(x => x.YachtId == reservation.YachtId, cancellationToken);
            if (y2 != null)
            {
                var displayYacht = string.IsNullOrWhiteSpace(msgCtx.YachtName) ? "the yacht" : msgCtx.YachtName.Trim();
                var period =
                    $"{reservation.StartDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)} – {reservation.EndDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)}";
                var amt = payRow?.Amount ?? (reservation.TotalPrice ?? 0);
                _notifications.InsertUserNotification(
                    reservation.UserId,
                    "Payment received",
                    $"Your card payment of {amt:0.00} EUR was recorded. {displayYacht} ({period}) is now confirmed.");
                _notifications.InsertUserNotification(
                    y2.OwnerId,
                    "Payment received",
                    $"A card payment of {amt:0.00} EUR was received for {displayYacht} ({period}). The booking is confirmed.");
            }

            return new PaymentIntentDto
            {
                Status = status,
                PaymentIntentId = request.PaymentIntentId,
            };
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    private void EnsureCanPayForReservation(
        DbReservation r,
        int? currentUserId,
        bool isAdmin,
        bool isYachtOwner,
        CancellationToken cancellationToken)
    {
        if (isAdmin)
            return;
        if (currentUserId is not { } uid)
            throw new UnauthorizedAccessException("You must be signed in to act on this reservation payment.");
        if (r.UserId == uid)
            return;
        if (isYachtOwner)
        {
            var ownerId = _context.Yachts.AsNoTracking()
                .Where(y => y.YachtId == r.YachtId)
                .Select(y => (int?)y.OwnerId)
                .FirstOrDefault();
            if (ownerId == uid)
                return;
        }
        throw new UnauthorizedAccessException("You are not allowed to act on this reservation payment.");
    }

    private bool HasAnyPositivePayment(int reservationId) =>
        _context.Payments.AsNoTracking()
            .Any(p => p.ReservationId == reservationId && p.Amount > 0);

    private static bool IsCardMethod(string? paymentMethod) =>
        !string.IsNullOrEmpty(paymentMethod) && paymentMethod.Contains("card", StringComparison.OrdinalIgnoreCase);

    private bool HasNonCardPayment(int reservationId) =>
        _context.Payments.AsNoTracking()
            .Any(p => p.ReservationId == reservationId && p.Amount > 0 && !IsCardMethod(p.PaymentMethod));

    private bool HasCardPaymentForReservation(int reservationId) =>
        _context.Payments.AsNoTracking()
            .Any(p => p.ReservationId == reservationId && p.Amount > 0 && IsCardMethod(p.PaymentMethod));

    private void PublishPaymentCompleted(
        DbPayment payment,
        string paymentMethod,
        string payStatus,
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
            PaymentStatus = payStatus,
            IsConfirmed = isConfirmed,
            UserEmail = msgCtx?.UserEmail,
            UserName = msgCtx?.UserDisplayName,
            YachtName = msgCtx?.YachtName,
            ReservationStartDate = res?.StartDate,
            ReservationEndDate = res?.EndDate,
        };
        _messagePublisher.Publish(MessageEnvelope.PaymentCompleted, JsonSerializer.Serialize(msg));

        if (res == null || msgCtx == null)
            return;
        var yacht = _context.Yachts.Find(res.YachtId);
        if (yacht == null)
            return;
        var pr =
            $"{res.StartDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)} – {res.EndDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)}";
        var yn = string.IsNullOrWhiteSpace(msgCtx.YachtName) ? "your booking" : msgCtx.YachtName.Trim();
        _notifications.InsertUserNotification(
            res.UserId,
            "Payment recorded",
            $"A {paymentMethod} payment of {payment.Amount:0.00} EUR was recorded for {yn} ({pr}).");
        _notifications.InsertUserNotification(
            yacht.OwnerId,
            "Payment recorded",
            $"Payment of {payment.Amount:0.00} EUR ({paymentMethod}) for {yn} ({pr}) was added to the reservation.");
    }
}
