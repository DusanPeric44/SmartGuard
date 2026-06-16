using MassTransit;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using SmartGuard.Model.Options;
using SmartGuard.Notifications.Microservice.Consumers;
using SmartGuard.Notifications.Microservice.Database;
using SmartGuard.Notifications.Microservice.Interfaces;
using SmartGuard.Notifications.Microservice.Redis;
using SmartGuard.Notifications.Microservice.Services;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using StackExchange.Redis;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        corsBuilder =>
        {
            corsBuilder.AllowAnyOrigin()
                       .AllowAnyMethod()
                       .AllowAnyHeader();
        });
});

builder.Services.AddControllers();
builder.Services.AddSignalR();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Version = "v1",
        Title = "SmartGuard Notifications Microservice",
        Description = "Notifications hub + notifications persistence API"
    });

    options.AddSecurityDefinition(JwtBearerDefaults.AuthenticationScheme, new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = JwtBearerDefaults.AuthenticationScheme,
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "JWT Authorization header using the Bearer scheme."
    });

    options.AddSecurityRequirement(document => new OpenApiSecurityRequirement
    {
        [new OpenApiSecuritySchemeReference(JwtBearerDefaults.AuthenticationScheme, document)] = []
    });
});

var jwtSettings = builder.Configuration.GetSection("Jwt");
var secretKey = Encoding.ASCII.GetBytes(jwtSettings["Secret"] ?? "DefaultSecretKeyForSmartGuardAPI1234567890");

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(secretKey),
        ValidateIssuer = true,
        ValidIssuer = jwtSettings["Issuer"],
        ValidateAudience = true,
        ValidAudience = jwtSettings["Audience"],
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
    };

    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["access_token"];
            var path = context.HttpContext.Request.Path;

            if (!string.IsNullOrWhiteSpace(accessToken) &&
                path.StartsWithSegments("/hub/notifications"))
            {
                context.Token = accessToken;
            }

            return Task.CompletedTask;
        }
    };
});

var redisConfiguration = builder.Configuration["Redis:Configuration"];
if (!string.IsNullOrWhiteSpace(redisConfiguration))
{
    builder.Services.AddStackExchangeRedisCache(o => o.Configuration = redisConfiguration);
    builder.Services.AddSingleton<IConnectionMultiplexer>(_ => ConnectionMultiplexer.Connect(redisConfiguration));
    builder.Services.AddSingleton<IRedisConnectionStore, RedisConnectionStore>();
}
else
{
    builder.Services.AddDistributedMemoryCache();
    builder.Services.AddSingleton<IRedisConnectionStore, InMemoryConnectionStore>();
}

builder.Services.AddDbContext<NotificationsDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("NotificationsDatabase")));

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
            ProjectId = "smartguard-54863"
        });
    }
    catch (InvalidOperationException)
    {
        var credential = GoogleCredential.GetApplicationDefault();
        return FirebaseApp.Create(new AppOptions
        {
            Credential = credential,
            ProjectId = "smartguard-54863"
        });
    }
});

builder.Services.AddSingleton(sp =>
{
    var app = sp.GetRequiredService<FirebaseApp>();
    return FirebaseMessaging.GetMessaging(app);
});

builder.Services.AddSingleton<IFCMService, FCMService>();
builder.Services.AddScoped<INotificationsRealtimePublisher, NotificationsRealtimePublisher>();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<SmartGuard.Model.Interfaces.IUserContext, UserContext>();

// Configure MassTransit
var rabbitMqVHost = builder.Configuration["RabbitMQ:VirtualHost"] ?? "/";

builder.Services.AddMassTransit(x =>
{
    x.AddConsumer<NotificationConsumer>();

    x.UsingRabbitMq((context, cfg) =>
    {
        cfg.Host(builder.Configuration["RabbitMQ:Host"] ?? "localhost", rabbitMqVHost, h =>
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

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<NotificationsDbContext>();
    await db.Database.MigrateAsync();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers().RequireAuthorization();
app.MapHub<SmartGuard.Notifications.Microservice.Hubs.NotificationsHub>("/hub/notifications").RequireAuthorization();

app.Run();
