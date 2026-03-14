namespace Yamore.API.Services;

/// <summary>
/// Publishes messages to RabbitMQ for the auxiliary worker to process asynchronously.
/// </summary>
public interface IMessagePublisher
{
    void Publish(string messageType, string payloadJson);
}
