using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Yamore.Services.Interfaces;

namespace Yamore.API.Hosted;

/// <summary>Periodically marks confirmed reservations as completed after <see cref="Yamore.Model.Reservation.EndDate"/>.</summary>
public sealed class AutoCompleteReservationsHostedService : BackgroundService
{
    private static readonly TimeSpan Period = TimeSpan.FromMinutes(15);
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<AutoCompleteReservationsHostedService> _logger;

    public AutoCompleteReservationsHostedService(
        IServiceProvider serviceProvider,
        ILogger<AutoCompleteReservationsHostedService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await Task.Yield();
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await Task.Delay(Period, stoppingToken);
                using var scope = _serviceProvider.CreateScope();
                var reservations = scope.ServiceProvider.GetRequiredService<IReservationService>();
                var n = reservations.AutoCompletePastTrips();
                if (n > 0)
                    _logger.LogInformation("Auto-completed {Count} reservation(s) (trip end passed).", n);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "AutoCompletePastTrips failed; will retry on next interval.");
            }
        }
    }
}
