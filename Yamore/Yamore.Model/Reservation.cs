using System;
using System.Text.Json.Serialization;

namespace Yamore.Model
{
    public class Reservation
    {
        [JsonPropertyName("reservationId")]
        public int ReservationId { get; set; }

        [JsonPropertyName("userId")]
        public int UserId { get; set; }

        [JsonPropertyName("yachtId")]
        public int YachtId { get; set; }

        [JsonPropertyName("startDate")]
        public DateTime StartDate { get; set; }

        [JsonPropertyName("endDate")]
        public DateTime EndDate { get; set; }

        [JsonPropertyName("totalPrice")]
        public decimal? TotalPrice { get; set; }

        [JsonPropertyName("status")]
        public string? Status { get; set; }

        [JsonPropertyName("createdAt")]
        public DateTime? CreatedAt { get; set; }
    }
}
