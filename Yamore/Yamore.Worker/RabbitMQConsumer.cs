using System.Text;
using System.Text.Json;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using Yamore.Model.Messages;

namespace Yamore.Worker;

public class RabbitMQConsumer : IDisposable
{
    private static readonly int[] _retryDelaysMs = { 1000, 2000, 4000, 8000 };

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
        {
            return;
        }

        // Drop any half-open resources from a previous failed start
        TeardownConnection(reason: "before reconnect");

        var hostName = _configuration["RabbitMQ:HostName"];
        if (string.IsNullOrWhiteSpace(hostName))
        {
            _logger.LogWarning("RabbitMQ:HostName not configured. Worker will not consume messages.");
            return;
        }

        var portStr = _configuration["RabbitMQ:Port"];
        var port = 5672;
        if (!string.IsNullOrWhiteSpace(portStr) && int.TryParse(portStr, out var p))
        {
            port = p;
        }

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
            DispatchConsumersAsync = true,
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
                "Could not connect to RabbitMQ at {HostName}:{Port}. The worker will keep trying on its reconnect loop. Ensure RabbitMQ is running (e.g. Docker: docker run -d -p 5672:5672 -p 15672:15672 rabbitmq:3-management).",
                hostName,
                port);
            TeardownConnection(reason: "connection failed");
            return;
        }

        try
        {
            _channel!.QueueDeclare(queue: queueName, durable: true, exclusive: false, autoDelete: false, arguments: null);
            _channel.BasicQos(prefetchSize: 0, prefetchCount: 1, global: false);

            var consumer = new AsyncEventingBasicConsumer(_channel);
            consumer.Received += async (_, ea) =>
            {
                // Copy body before any await; buffer may be released after the handler returns.
                var bodyCopy = ea.Body.ToArray();

                string json;
                try
                {
                    json = Encoding.UTF8.GetString(bodyCopy);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to decode message body as UTF-8; acknowledging to drop invalid payload.");
                    SafeAck(ea.DeliveryTag);
                    return;
                }

                MessageEnvelope? envelope;
                try
                {
                    envelope = JsonSerializer.Deserialize<MessageEnvelope>(json);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Invalid JSON in message; acknowledging to drop poison payload.");
                    SafeAck(ea.DeliveryTag);
                    return;
                }

                if (envelope == null)
                {
                    _logger.LogWarning("Deserialized message envelope is null; acknowledging.");
                    SafeAck(ea.DeliveryTag);
                    return;
                }

                var channel = _channel;
                if (channel == null || !channel.IsOpen)
                {
                    _logger.LogError("Channel is null or closed before processing; cannot ack/nack. DeliveryTag={Tag}", ea.DeliveryTag);
                    return;
                }

                Exception? lastEx = null;
                for (var attempt = 0; attempt < 5; attempt++)
                {
                    try
                    {
                        await _handler.HandleAsync(envelope.MessageType, envelope.PayloadJson).ConfigureAwait(false);
                        if (!channel.IsOpen)
                        {
                            _logger.LogError("Channel closed after handle; cannot ack. DeliveryTag={Tag}", ea.DeliveryTag);
                            return;
                        }

                        channel.BasicAck(ea.DeliveryTag, false);
                        return;
                    }
                    catch (Exception ex)
                    {
                        lastEx = ex;
                        if (attempt < 4)
                        {
                            var delayMs = _retryDelaysMs[attempt];
                            _logger.LogWarning(
                                ex,
                                "Error processing message (attempt {Attempt}/5). Retrying after {DelayMs} ms.",
                                attempt + 1,
                                delayMs);
                            await Task.Delay(delayMs).ConfigureAwait(false);
                        }
                    }
                }

                _logger.LogError(
                    lastEx,
                    "Message processing failed after {Attempts} attempts; nack without requeue (message will be discarded or sent to DLQ if configured). MessageType={MessageType}",
                    5,
                    envelope.MessageType);
                if (channel.IsOpen)
                {
                    try
                    {
                        channel.BasicNack(ea.DeliveryTag, false, requeue: false);
                    }
                    catch (Exception nackEx)
                    {
                        _logger.LogError(nackEx, "BasicNack failed for delivery {Tag}", ea.DeliveryTag);
                    }
                }
            };

            _consumerTag = _channel.BasicConsume(queue: queueName, autoAck: false, consumer: consumer);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to set up queue or consumer for RabbitMQ; tearing down connection.");
            TeardownConnection(reason: "setup failed");
        }

        if (IsRunning)
        {
            _logger.LogInformation("Worker consuming from queue {Queue} on {HostName}:{Port} (AsyncEventingBasicConsumer).", queueName, hostName, port);
        }
        }
    }

    private void SafeAck(ulong deliveryTag)
    {
        try
        {
            if (_channel is { IsOpen: true })
            {
                _channel.BasicAck(deliveryTag, false);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "BasicAck failed for delivery {Tag}", deliveryTag);
        }
    }

    private void TeardownConnection(string reason)
    {
        try
        {
            if (_channel != null)
            {
                try
                {
                    if (_channel.IsOpen)
                    {
                        _channel.Close();
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Error closing RabbitMQ channel ({Reason}).", reason);
                }

                try
                {
                    _channel.Dispose();
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Error disposing RabbitMQ channel ({Reason}).", reason);
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Unexpected error while tearing down RabbitMQ channel ({Reason}).", reason);
        }
        finally
        {
            _channel = null;
            _consumerTag = null;
        }

        try
        {
            if (_connection != null)
            {
                try
                {
                    if (_connection.IsOpen)
                    {
                        _connection.Close();
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Error closing RabbitMQ connection ({Reason}).", reason);
                }

                try
                {
                    _connection.Dispose();
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Error disposing RabbitMQ connection ({Reason}).", reason);
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Unexpected error while tearing down RabbitMQ connection ({Reason}).", reason);
        }
        finally
        {
            _connection = null;
        }
    }

    public void Dispose()
    {
        TeardownConnection(reason: "dispose");
    }
}
