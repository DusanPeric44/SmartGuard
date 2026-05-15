using MassTransit;
using SmartGuard.Model.Options;
using SmartGuard.Notifications.Microservice.Consumers;
using SmartGuard.Notifications.Microservice.Interfaces;
using SmartGuard.Notifications.Microservice.Services;

var builder = Host.CreateApplicationBuilder(args);

// Add Services
builder.Services.Configure<SmtpOptions>(builder.Configuration.GetSection("Smtp"));
builder.Services.AddSingleton<IMailingService, MailingService>();
builder.Services.AddSingleton<IFCMService, FCMService>();

// Configure MassTransit
builder.Services.AddMassTransit(x =>
{
    x.AddConsumer<NotificationConsumer>();

    x.UsingRabbitMq((context, cfg) =>
    {
        cfg.Host(builder.Configuration["RabbitMQ:Host"] ?? "localhost", "/", h =>
        {
            h.Username(builder.Configuration["RabbitMQ:Username"] ?? "guest");
            h.Password(builder.Configuration["RabbitMQ:Password"] ?? "guest");
        });

        cfg.ReceiveEndpoint("notification-worker-queue", e =>
        {
            // Exponential backoff retry logic
            e.UseMessageRetry(r => r.Exponential(5, TimeSpan.FromSeconds(2), TimeSpan.FromSeconds(30), TimeSpan.FromSeconds(5)));
            
            e.ConfigureConsumer<NotificationConsumer>(context);
        });
    });
});

var host = builder.Build();
host.Run();
