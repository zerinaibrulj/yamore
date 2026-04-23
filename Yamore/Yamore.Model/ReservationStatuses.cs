using System;

namespace Yamore.Model
{
    /// <summary>Reservation lifecycle values (soft transitions; logic is centralized in ReservationService).</summary>
    public static class ReservationStatuses
    {
        public const string Pending = "Pending";
        public const string Confirmed = "Confirmed";
        public const string Completed = "Completed";
        public const string Cancelled = "Cancelled";

        public static bool IsTerminal(string? status) =>
            string.Equals(status, Cancelled, StringComparison.OrdinalIgnoreCase)
            || string.Equals(status, Completed, StringComparison.OrdinalIgnoreCase);

        public static bool BlocksAvailability(string? status) =>
            !string.Equals(status, Cancelled, StringComparison.OrdinalIgnoreCase)
            && !string.Equals(status, Completed, StringComparison.OrdinalIgnoreCase);
    }
}
