using Yamore.Model;
using Yamore.Model.Requests.Payment;
using Yamore.Model.Requests.Reservation;

namespace Yamore.API.Services;

public interface IPaymentWorkflowService
{
    string GetStripePublishableKey();

    Task<PaymentIntentDto> PrepareProvisionalCardBookingAsync(
        PrepareCardBookingRequest request,
        int claimUserId,
        CancellationToken cancellationToken);

    Task<PaymentIntentDto> CreateIntentForExistingReservationAsync(
        CreatePaymentIntentRequest request,
        int currentUserId,
        bool isAdmin,
        bool isYachtOwner,
        CancellationToken cancellationToken);

    /// <param name="currentUserId">Authenticated user id from claims, if any.</param>
    Task<PaymentIntentDto> ConfirmPaymentAsync(
        ConfirmPaymentRequest request,
        int? currentUserId,
        bool isAdmin,
        bool isYachtOwner,
        CancellationToken cancellationToken);

    /// <summary>Verifies the Stripe-Signature, then runs the same idempotent finalization as HTTP confirm (optional when secret is not configured).</summary>
    Task<StripeWebhookHandleResult> ProcessStripeWebhookAsync(
        string json,
        string stripeSignatureHeader,
        CancellationToken cancellationToken);
}
