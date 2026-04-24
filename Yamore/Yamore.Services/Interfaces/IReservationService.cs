using Yamore.Model;
using Yamore.Model.Requests.Reservation;
using Yamore.Model.SearchObjects;
using DatabaseReservation = Yamore.Services.Database.Reservation;

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

        /// <summary>
        /// Updates a tracked <see cref="Yamore.Services.Database.Reservation"/> to confirmed after a successful card payment. Does <b>not</b> call
        /// <c>SaveChanges</c> — the caller (orchestrator) writes once with the payment row on the same <see cref="Microsoft.EntityFrameworkCore.DbContext"/>.
        /// </summary>
        void ApplyCardPaymentConfirmation(DatabaseReservation entity, int? paidByUserId);

        /// <summary>Validates the yacht, overlap, and add-on services; returns the total price in EUR (server-side, same rules as the mobile app). Does not persist changes.</summary>
        decimal ValidateAndQuoteCardBooking(int yachtId, DateTime start, DateTime end, IReadOnlyList<int> serviceIds);

        /// <summary>Creates a confirmed reservation, add-on lines, and optionally a pending card payment in one database transaction.</summary>
        Model.Reservation InsertConfirmedReservationWithServices(ReservationInsertRequest request, IReadOnlyList<int> serviceIds, CardPaymentPendingInfo? recordPendingCardPayment = null);

        /// <summary>Loads user and yacht fields for messaging (no visibility filtering).</summary>
        ReservationMessageContext GetReservationMessageContext(int userId, int yachtId);

        /// <summary>Sets <see cref="ReservationStatuses.Confirmed"/> reservations to <see cref="ReservationStatuses.Completed"/> when <c>EndDate</c> has passed (background use).</summary>
        int AutoCompletePastTrips();
    }
}
