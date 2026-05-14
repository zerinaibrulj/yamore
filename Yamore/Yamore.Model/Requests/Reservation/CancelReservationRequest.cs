using System.Text.Json.Serialization;

namespace Yamore.Model.Requests.Reservation
{
    public class CancelReservationRequest
    {
        /// <summary>
        /// Reason for cancellation (required when an administrator or yacht owner cancels the guest booking).
        /// </summary>
        public string? CancellationReason { get; set; }

        /// <summary>Legacy JSON key; combined with <see cref="CancellationReason"/>.</summary>
        [JsonPropertyName("reason")]
        public string? Reason { get; set; }

        /// <summary>Effective message for validation and audit (prefers <see cref="CancellationReason"/>).</summary>
        public string? GetEffectiveCancellationMessage() =>
            !string.IsNullOrWhiteSpace(CancellationReason)
                ? CancellationReason.Trim()
                : !string.IsNullOrWhiteSpace(Reason)
                    ? Reason!.Trim()
                    : null;
    }
}
