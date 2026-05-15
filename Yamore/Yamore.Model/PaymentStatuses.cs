using System;

namespace Yamore.Model
{
    /// <summary>Payment row statuses (must match SQL CHECK on [Payments].[Status]: Pending, Failed, Success).</summary>
    public static class PaymentStatuses
    {
        /// <summary>Stored in DB after a successful card charge or settled payment.</summary>
        public const string Success = "Success";

        public const string Pending = "Pending";
        public const string Failed = "Failed";

        /// <summary>Stripe PaymentIntent status (API only — map to <see cref="Success"/> when persisting).</summary>
        public const string StripeSucceeded = "succeeded";

        /// <summary>Legacy/alternate spelling used in some reporting filters.</summary>
        public const string Paid = "paid";

        public static bool IsRevenueRecognized(string? status) =>
            string.Equals(status, Success, StringComparison.OrdinalIgnoreCase)
            || string.Equals(status, StripeSucceeded, StringComparison.OrdinalIgnoreCase)
            || string.Equals(status, Paid, StringComparison.OrdinalIgnoreCase);

        public static bool IsPending(string? status) =>
            string.Equals(status, Pending, StringComparison.OrdinalIgnoreCase)
            || string.Equals(status, "pending", StringComparison.OrdinalIgnoreCase);

        public static bool IsCardMethod(string? paymentMethod) =>
            !string.IsNullOrEmpty(paymentMethod)
            && paymentMethod.Contains("card", StringComparison.OrdinalIgnoreCase);

        /// <summary>
        /// Card payments still marked pending while the reservation is confirmed/completed.
        /// </summary>
        public static bool IsSettledCardAwaitingStatusUpdate(
            string? paymentStatus,
            string? paymentMethod,
            string? reservationStatus) =>
            IsPending(paymentStatus)
            && IsCardMethod(paymentMethod)
            && (string.Equals(reservationStatus, ReservationStatuses.Confirmed, StringComparison.OrdinalIgnoreCase)
                || string.Equals(reservationStatus, ReservationStatuses.Completed, StringComparison.OrdinalIgnoreCase));

        public static bool CountsTowardRevenue(
            string? paymentStatus,
            string? paymentMethod,
            string? reservationStatus) =>
            IsRevenueRecognized(paymentStatus)
            || IsSettledCardAwaitingStatusUpdate(paymentStatus, paymentMethod, reservationStatus);

        /// <summary>Value to persist on <see cref="Services.Database.Payment.Status"/> after Stripe confirms.</summary>
        public static string DbStatusForSuccessfulCharge() => Success;
    }
}
