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

        while (!stoppingToken.IsCancellationRequested)
        {
            if (!_consumer.IsRunning)
            {
                _logger.LogWarning("RabbitMQ consumer is not running. Retrying connection...");
                _consumer.Start();
            }

            await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);
        }
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        _consumer.Dispose();
        await base.StopAsync(cancellationToken);
    }
}
