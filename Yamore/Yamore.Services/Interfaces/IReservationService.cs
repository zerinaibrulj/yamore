using Yamore.Model;
using Yamore.Model.Requests.Reservation;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface IReservationService : ICRUDService<Model.Reservation, ReservationSearchObject, ReservationInsertRequest, ReservationUpdateRequest, ReservationDeleteRequest>
    {
        /// <summary>Admin or yacht owner confirms a <see cref="ReservationStatuses.Pending"/> reservation.</summary>
        Model.Reservation Confirm(int id, int actorUserId, bool actorIsAdmin, bool actorIsYachtOwner);

        /// <summary>Guest, owner, or admin cancels an active reservation (not completed).</summary>
        CancelReservationOutcome Cancel(int id, int actorUserId, bool actorIsAdmin, string? reason);

        /// <summary>Admin-only: decline a pending booking (stored as cancelled with audit reason).</summary>
        Model.Reservation Reject(int id, int adminUserId, string reason);

        /// <summary>Marks a confirmed trip as completed after <see cref="Model.Reservation.EndDate"/> (UTC).</summary>
        Model.Reservation Complete(int id, int actorUserId, bool actorIsAdmin);

        /// <summary>After Stripe reports success for an existing reservation; idempotent if already confirmed.</summary>
        Model.Reservation ConfirmFromSuccessfulCardPayment(int reservationId, int? paidByUserId);

        /// <summary>Validates the yacht, overlap, and add-on services; returns the total price in EUR (server-side, same rules as the mobile app).</summary>
        decimal ValidateAndQuoteCardBooking(int yachtId, DateTime start, DateTime end, IReadOnlyList<int> serviceIds);

        /// <summary>Creates a confirmed reservation and add-on lines in one transaction. Total must match <see cref="ValidateAndQuoteCardBooking"/> for the same inputs (within 0.02 EUR).</summary>
        Model.Reservation InsertConfirmedReservationWithServices(ReservationInsertRequest request, IReadOnlyList<int> serviceIds);

        /// <summary>Loads user and yacht fields for messaging (no visibility filtering).</summary>
        ReservationMessageContext GetReservationMessageContext(int userId, int yachtId);

        /// <summary>Sets <see cref="ReservationStatuses.Confirmed"/> reservations to <see cref="ReservationStatuses.Completed"/> when <c>EndDate</c> has passed (background use).</summary>
        int AutoCompletePastTrips();
    }
}
