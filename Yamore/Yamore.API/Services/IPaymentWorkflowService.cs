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
        CancellationToken cancellationToken);

    /// <param name="currentUserId">Authenticated user id from claims, if any.</param>
    Task<PaymentIntentDto> ConfirmPaymentAsync(
        ConfirmPaymentRequest request,
        int? currentUserId,
        CancellationToken cancellationToken);
}
