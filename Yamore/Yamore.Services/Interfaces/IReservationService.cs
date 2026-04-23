using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.Requests.Reservation;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface IReservationService : ICRUDService<Model.Reservation, ReservationSearchObject, ReservationInsertRequest, ReservationUpdateRequest, ReservationDeleteRequest>
    {
        Model.Reservation Cancel(int id);
        Model.Reservation Confirm(int id);

        /// <summary>Validates the yacht, overlap, and add-on services; returns the total price in EUR (server-side, same rules as the mobile app).</summary>
        decimal ValidateAndQuoteCardBooking(int yachtId, DateTime start, DateTime end, IReadOnlyList<int> serviceIds);

        /// <summary>Creates a confirmed reservation and add-on lines in one transaction. Total must match <see cref="ValidateAndQuoteCardBooking"/> for the same inputs (within 0.02 EUR).</summary>
        Model.Reservation InsertConfirmedReservationWithServices(ReservationInsertRequest request, IReadOnlyList<int> serviceIds);

        /// <summary>Loads user and yacht fields for messaging (no visibility filtering).</summary>
        ReservationMessageContext GetReservationMessageContext(int userId, int yachtId);
    }
}
