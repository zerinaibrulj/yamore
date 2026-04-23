using System.Text;
using RabbitMQ.Client;
using System.Text.Json;
using Yamore.Model.Messages;

namespace Yamore.API.Services;

/// <summary>
/// Sends message envelopes to the configured RabbitMQ queue. Configure via environment variables
/// (RabbitMQ__HostName, RabbitMQ__UserName, etc.) or User Secrets — avoid committing credentials in appsettings.
/// Registered as a <b>singleton</b>: one <see cref="IConnection"/> and <see cref="IModel"/> for the app lifetime, not per publish.
/// </summary>
public class RabbitMQMessagePublisher : IMessagePublisher, IDisposable
{
    private readonly IConnection? _connection;
    private readonly IModel? _channel;
    private readonly string _queueName;
    private readonly ILogger<RabbitMQMessagePublisher> _logger;
    private readonly bool _isConfigured;

    public RabbitMQMessagePublisher(IConfiguration configuration, ILogger<RabbitMQMessagePublisher> logger)
    {
        _logger = logger;
        var hostName = configuration["RabbitMQ:HostName"];
        var portStr = configuration["RabbitMQ:Port"];
        var userName = configuration["RabbitMQ:UserName"];
        var password = configuration["RabbitMQ:Password"];
        var virtualHost = configuration["RabbitMQ:VirtualHost"] ?? "/";
        _queueName = configuration["RabbitMQ:QueueName"] ?? "yamore-tasks";

        if (string.IsNullOrWhiteSpace(hostName))
        {
            _logger.LogWarning("RabbitMQ is not configured (RabbitMQ:HostName missing). Messages will not be sent.");
            _isConfigured = false;
            return;
        }

        try
        {
            var port = 5672;
            if (!string.IsNullOrWhiteSpace(portStr) && int.TryParse(portStr, out var p))
                port = p;

            var factory = new ConnectionFactory
            {
                HostName = hostName,
                Port = port,
                UserName = string.IsNullOrWhiteSpace(userName) ? "guest" : userName,
                Password = string.IsNullOrWhiteSpace(password) ? "guest" : password,
                VirtualHost = virtualHost,
            };

            _connection = factory.CreateConnection();
            _channel = _connection.CreateModel();
            _channel.QueueDeclare(queue: _queueName, durable: true, exclusive: false, autoDelete: false, arguments: null);
            _isConfigured = true;
            _logger.LogInformation("RabbitMQ publisher connected to {HostName}:{Port}, queue: {Queue}", hostName, port, _queueName);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to connect to RabbitMQ. Messages will not be sent.");
            _isConfigured = false;
        }
    }

    public void Publish(string messageType, string payloadJson)
    {
        if (!_isConfigured || _channel == null)
        {
            return;
        }

        try
        {
            var envelope = new MessageEnvelope { MessageType = messageType, PayloadJson = payloadJson };
            var json = JsonSerializer.Serialize(envelope);
            var body = Encoding.UTF8.GetBytes(json);

            var props = _channel.CreateBasicProperties();
            props.Persistent = true;
            props.ContentType = "application/json";

            _channel.BasicPublish(exchange: "", routingKey: _queueName, basicProperties: props, body: body);
            _logger.LogDebug("Published message {MessageType} to {Queue}", messageType, _queueName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to publish message {MessageType}", messageType);
        }
    }

    public void Dispose()
    {
        try
        {
            if (_channel is { IsOpen: true })
            {
                _channel.Close();
            }
        }
        catch (Exception ex)
        {
            _logger.LogDebug(ex, "RabbitMQ publisher: channel close during dispose.");
        }

        try
        {
            _connection?.Close();
        }
        catch (Exception ex)
        {
            _logger.LogDebug(ex, "RabbitMQ publisher: connection close during dispose.");
        }

        try
        {
            _channel?.Dispose();
        }
        catch (Exception ex)
        {
            _logger.LogDebug(ex, "RabbitMQ publisher: channel dispose.");
        }

        try
        {
            _connection?.Dispose();
        }
        catch (Exception ex)
        {
            _logger.LogDebug(ex, "RabbitMQ publisher: connection dispose.");
        }
    }
}
