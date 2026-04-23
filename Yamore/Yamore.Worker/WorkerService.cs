namespace Yamore.Worker;

public class WorkerService : BackgroundService
{
    private readonly ILogger<WorkerService> _logger;
    private readonly RabbitMQConsumer _consumer;

    public WorkerService(ILogger<WorkerService> logger, RabbitMQConsumer consumer)
    {
        _logger = logger;
        _consumer = consumer;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Yamore.Worker starting.");
        _consumer.Start();

        var reconnectWaitSeconds = 1;

        while (!stoppingToken.IsCancellationRequested)
        {
            if (!_consumer.IsRunning)
            {
                _logger.LogWarning(
                    "RabbitMQ consumer is not running (not connected, channel closed, or not consuming). " +
                    "Attempting Start(); if still down, next wait {NextWaitSeconds}s (exponential backoff, max 8s).",
                    reconnectWaitSeconds);
                _consumer.Start();

                if (!_consumer.IsRunning)
                {
                    try
                    {
                        await Task.Delay(TimeSpan.FromSeconds(reconnectWaitSeconds), stoppingToken).ConfigureAwait(false);
                    }
                    catch (OperationCanceledException)
                    {
                        break;
                    }

                    reconnectWaitSeconds = reconnectWaitSeconds >= 8 ? 8 : Math.Min(8, reconnectWaitSeconds * 2);
                    continue;
                }

                _logger.LogInformation("RabbitMQ consumer is running; reset reconnect backoff to 1s.");
                reconnectWaitSeconds = 1;
            }
            else
            {
                reconnectWaitSeconds = 1;
            }

            try
            {
                await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken).ConfigureAwait(false);
            }
            catch (OperationCanceledException)
            {
                break;
            }
        }
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Yamore.Worker stopping; disposing RabbitMQ consumer.");
        _consumer.Dispose();
        await base.StopAsync(cancellationToken);
    }
}
