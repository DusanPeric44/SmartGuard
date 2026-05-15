using MassTransit;
using SmartGuard.Model.Options;
using SmartGuard.Notifications.Microservice.Consumers;
using SmartGuard.Notifications.Microservice.Interfaces;
using SmartGuard.Notifications.Microservice.Services;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;

var builder = Host.CreateApplicationBuilder(args);

// Add Services
builder.Services.Configure<SmtpOptions>(builder.Configuration.GetSection("Smtp"));
builder.Services.AddSingleton<IMailingService, MailingService>();

var firebaseServiceAccountPath = Environment.GetEnvironmentVariable("FIREBASE_SERVICE_ACCOUNT_PATH")
    ?? Path.Combine(builder.Environment.ContentRootPath, "firebase-service-account.json");

if (!File.Exists(firebaseServiceAccountPath))
{
    throw new FileNotFoundException($"Firebase service account file not found at '{firebaseServiceAccountPath}'.", firebaseServiceAccountPath);
}

if (string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS")))
{
    Environment.SetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", firebaseServiceAccountPath);
}

builder.Services.AddSingleton(_ =>
{
    try
    {
        var existing = FirebaseApp.DefaultInstance;
        if (existing != null)
        {
            return existing;
        }

        var credential = GoogleCredential.GetApplicationDefault();
        return FirebaseApp.Create(new AppOptions
        {
            Credential = credential,
            ProjectId = "smartguard-service"
        });
    }
    catch (InvalidOperationException)
    {
        var credential = GoogleCredential.GetApplicationDefault();
        return FirebaseApp.Create(new AppOptions
        {
            Credential = credential,
            ProjectId = "smartguard-service"
        });
    }
});

builder.Services.AddSingleton(sp =>
{
    var app = sp.GetRequiredService<FirebaseApp>();
    return FirebaseMessaging.GetMessaging(app);
});

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
