using System.Reflection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Yamore.Configuration;
using Yamore.Worker;

LocalEnvFileLoader.Load();
ConfigurationEnvAliases.Apply();

var builder = Host.CreateApplicationBuilder(args);

builder.Services.AddSingleton<MessageHandler>();
builder.Services.AddSingleton<RabbitMQConsumer>();
builder.Services.AddHostedService<WorkerService>();

var host = builder.Build();

{
    var startup = host.Services.GetRequiredService<ILoggerFactory>().CreateLogger("Yamore.Worker.Startup");
    var env = host.Services.GetRequiredService<IHostEnvironment>();
    var cfg = host.Services.GetRequiredService<IConfiguration>();
    var version = typeof(Program).Assembly.GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion
        ?? typeof(Program).Assembly.GetName().Version?.ToString()
        ?? "unknown";
    startup.LogInformation(
        "Yamore.Worker process started. Version={Version}, Environment={Env}, Machine={Machine}, DockerEnv={InDocker}, RabbitMQ {Host}:{Port} vhost={VHost} queue={Queue}, Framework={Fx}",
        version,
        env.EnvironmentName,
        Environment.MachineName,
        File.Exists("/.dockerenv"),
        cfg["RabbitMQ:HostName"] ?? "(unset)",
        cfg["RabbitMQ:Port"] ?? "5672",
        cfg["RabbitMQ:VirtualHost"] ?? "/",
        cfg["RabbitMQ:QueueName"] ?? "(unset)",
        System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription);
}

{
    var fatal = host.Services.GetRequiredService<ILoggerFactory>().CreateLogger("Yamore.Worker");
    AppDomain.CurrentDomain.UnhandledException += (_, e) =>
    {
        if (e.ExceptionObject is Exception ex)
        {
            fatal.LogCritical(ex, "Unhandled AppDomain exception. IsTerminating={Terminating}.", e.IsTerminating);
        }
        else
        {
            fatal.LogCritical("Unhandled non-exception. IsTerminating={Terminating}, Value={Value}", e.IsTerminating, e.ExceptionObject);
        }
    };
    TaskScheduler.UnobservedTaskException += (_, e) =>
    {
        fatal.LogError(e.Exception, "Unobserved task exception.");
        e.SetObserved();
    };
}

host.Run();
