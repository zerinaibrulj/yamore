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
            await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
    }
}
