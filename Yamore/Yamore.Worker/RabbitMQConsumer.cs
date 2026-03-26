using System.Text;
using System.Text.Json;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using Yamore.Model.Messages;

namespace Yamore.Worker;

public class RabbitMQConsumer : IDisposable
{
    private readonly ILogger<RabbitMQConsumer> _logger;
    private readonly IConfiguration _configuration;
    private readonly MessageHandler _handler;
    private IConnection? _connection;
    private IModel? _channel;
    private string? _consumerTag;
    private readonly object _sync = new();

    public bool IsRunning => _connection?.IsOpen == true && _channel?.IsOpen == true && !string.IsNullOrWhiteSpace(_consumerTag);

    public RabbitMQConsumer(
        ILogger<RabbitMQConsumer> logger,
        IConfiguration configuration,
        MessageHandler handler)
    {
        _logger = logger;
        _configuration = configuration;
        _handler = handler;
    }

    public void Start()
    {
        lock (_sync)
        {
            if (IsRunning)
                return;
        }

        var hostName = _configuration["RabbitMQ:HostName"];
        if (string.IsNullOrWhiteSpace(hostName))
        {
            _logger.LogWarning("RabbitMQ:HostName not configured. Worker will not consume messages.");
            return;
        }

        var portStr = _configuration["RabbitMQ:Port"];
        var port = 5672;
        if (!string.IsNullOrWhiteSpace(portStr) && int.TryParse(portStr, out var p))
            port = p;

        var userName = _configuration["RabbitMQ:UserName"] ?? "guest";
        var password = _configuration["RabbitMQ:Password"] ?? "guest";
        var virtualHost = _configuration["RabbitMQ:VirtualHost"] ?? "/";
        var queueName = _configuration["RabbitMQ:QueueName"] ?? "yamore-tasks";

        var factory = new ConnectionFactory
        {
            HostName = hostName,
            Port = port,
            UserName = userName,
            Password = password,
            VirtualHost = virtualHost,
        };

        try
        {
            _connection = factory.CreateConnection();
            _channel = _connection.CreateModel();
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
                ex,
                "Could not connect to RabbitMQ at {HostName}:{Port}. Start RabbitMQ (e.g. Docker: docker run -d -p 5672:5672 -p 15672:15672 rabbitmq:3-management) and restart the Worker. The Worker will keep running but will not process messages until RabbitMQ is available.",
                hostName,
                port);
            return;
        }
        _channel.QueueDeclare(queue: queueName, durable: true, exclusive: false, autoDelete: false, arguments: null);
        _channel.BasicQos(prefetchSize: 0, prefetchCount: 1, global: false);

        var consumer = new EventingBasicConsumer(_channel);
        consumer.Received += async (_, ea) =>
        {
            try
            {
                var body = ea.Body.ToArray();
                var json = Encoding.UTF8.GetString(body);
                var envelope = JsonSerializer.Deserialize<MessageEnvelope>(json);
                if (envelope == null)
                {
                    _logger.LogWarning("Received message with null envelope.");
                    _channel?.BasicAck(ea.DeliveryTag, false);
                    return;
                }

                await _handler.HandleAsync(envelope.MessageType, envelope.PayloadJson);
                _channel?.BasicAck(ea.DeliveryTag, false);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing message.");
                _channel?.BasicNack(ea.DeliveryTag, false, true);
            }
        };

        _consumerTag = _channel.BasicConsume(queue: queueName, autoAck: false, consumer: consumer);
        _logger.LogInformation("Worker consuming from queue {Queue} on {HostName}:{Port}", queueName, hostName, port);
    }

    public void Dispose()
    {
        try { _channel?.Close(); } catch { }
        try { _connection?.Close(); } catch { }
    }
}
