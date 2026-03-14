namespace Yamore.Model.Messages
{
    /// <summary>
    /// Envelope for RabbitMQ messages. Type discriminator allows the consumer to deserialize to the correct payload.
    /// </summary>
    public class MessageEnvelope
    {
        public const string ReservationCreated = "ReservationCreated";
        public const string PaymentCompleted = "PaymentCompleted";
        public const string ReviewSubmitted = "ReviewSubmitted";

        public string MessageType { get; set; } = "";
        public string PayloadJson { get; set; } = "";
    }
}
