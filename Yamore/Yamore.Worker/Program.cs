using Yamore.Worker;

var builder = Host.CreateApplicationBuilder(args);

builder.Services.AddSingleton<MessageHandler>();
builder.Services.AddSingleton<RabbitMQConsumer>();
builder.Services.AddHostedService<WorkerService>();

var host = builder.Build();
host.Run();
