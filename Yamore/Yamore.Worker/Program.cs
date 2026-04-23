using Yamore.Worker;

// Load the same .env as the API (RabbitMQ, SMTP, etc.) before host configuration.
LocalEnvFileLoader.Load();
ConfigurationEnvAliases.Apply();

var builder = Host.CreateApplicationBuilder(args);

builder.Services.AddSingleton<MessageHandler>();
builder.Services.AddSingleton<RabbitMQConsumer>();
builder.Services.AddHostedService<WorkerService>();

var host = builder.Build();
host.Run();
