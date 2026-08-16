using Duende.IdentityServer;
using MassTransit;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using SmartGuard.API.Consumers;
using SmartGuard.API.Extensions;
using SmartGuard.API.Hubs;
using SmartGuard.API.Middleware;
using SmartGuard.API.Services;
using SmartGuard.API.Grpc;
using SmartGuard.Model.Events;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Options;
using SmartGuard.Model.Requests;
using SmartGuard.Services;
using SmartGuard.Services.Database;
using System.IdentityModel.Tokens.Jwt;
using System.Text;
using System.Security.Claims;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        builder =>
        {
            builder.AllowAnyOrigin()
                   .AllowAnyMethod()
                   .AllowAnyHeader();
        });
});

// 1. Database Configuration
builder.Services.AddDbContext<SmartGuardContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// 2. Identity Configuration
builder.Services.AddIdentity<ApplicationUser, ApplicationRole>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequireLowercase = true;
    options.Password.RequireNonAlphanumeric = true;
    options.Password.RequireUppercase = true;
    options.Password.RequiredLength = 6;
    options.User.RequireUniqueEmail = true;
})
.AddRoles<ApplicationRole>()
.AddEntityFrameworkStores<SmartGuardContext>()
.AddDefaultTokenProviders();

builder.Services.AddIdentityServerConfiguration();

builder.Services.AddHttpContextAccessor();
builder.Services.AddSingleton<AuditLogChannel>();
builder.Logging.Services.AddSingleton<ILoggerProvider, AuditLoggerProvider>();
builder.Services.AddHostedService<AuditLoggerBackgroundWriter>();

// 3. Authentication Configuration
var jwtSettings = builder.Configuration.GetSection("Jwt");
var jwtSecret = jwtSettings["Secret"];
if (string.IsNullOrWhiteSpace(jwtSecret) || jwtSecret.Length < 32)
{
    throw new InvalidOperationException(
        "Jwt:Secret is not configured or is too short (minimum 32 characters). " +
        "Set the JWT_SECRET environment variable or Jwt:Secret in configuration before starting the API.");
}
var secretKey = Encoding.ASCII.GetBytes(jwtSecret);

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
})
 .AddGoogle(options =>
 {
     options.SignInScheme = IdentityServerConstants.ExternalCookieAuthenticationScheme;
     options.ClientId = builder.Configuration["Google:ClientId"] ?? "dummy";
     options.ClientSecret = builder.Configuration["Google:ClientSecret"] ?? "dummy";
     options.CallbackPath = "/auth/google";
     options.Scope.Add("profile");
     options.Events.OnTicketReceived = async ctx =>
     {
         ctx.HandleResponse();

         var principal = ctx.Principal;
         var email = principal?.FindFirst("email")?.Value?.Trim()
                     ?? principal?.FindFirst(JwtRegisteredClaimNames.Email)?.Value?.Trim()
                     ?? principal?.FindFirst(ClaimTypes.Email)?.Value?.Trim()
                     ?? string.Empty;

         if (string.IsNullOrWhiteSpace(email))
         {
             ctx.Response.Redirect(IdentityServerExtensions.BuildGoogleCallbackUrl(error: "invalid_google_login"));
             return;
         }

         var firstName = principal?.Claims.FirstOrDefault(c => c.Type == ClaimTypes.GivenName)?.Value?.Trim() ?? string.Empty;
         var lastName = principal?.Claims.FirstOrDefault(c => c.Type == ClaimTypes.Surname)?.Value?.Trim() ?? string.Empty;

         try
         {
             var authService = ctx.HttpContext.RequestServices.GetRequiredService<IAuthService>();
             var response = await authService.ExternalProviderCallbackAsync(new ExternalProviderCallbackRequest
             {
                 Provider = "Google",
                 Email = email,
                 FirstName = firstName,
                 LastName = lastName
             });

             await ctx.HttpContext.SignOutAsync(IdentityServerConstants.ExternalCookieAuthenticationScheme);

             ctx.Response.Redirect(IdentityServerExtensions.BuildGoogleCallbackUrl(token: response.Token,
                                                                                   refreshToken: response.RefreshToken));
         }
         catch (UnauthorizedAccessException ex)
         {
             ctx.Response.Redirect(IdentityServerExtensions.BuildGoogleCallbackUrl(error: ex.Message));
         }
         catch (Exception ex)
         {
             ctx.Response.Redirect(IdentityServerExtensions.BuildGoogleCallbackUrl(error: ex.Message));
         }
     };
     options.Events.OnRemoteFailure = async ctx =>
     {
         ctx.HandleResponse();
         ctx.Response.Redirect(IdentityServerExtensions.BuildGoogleCallbackUrl(error: ctx.Failure?.Message ?? "google_login_failed"));
     };
 })
 .AddMicrosoftAccount(options =>
 {
     options.ClientId = builder.Configuration["AzureAd:ClientId"] ?? "dummy";
     options.ClientSecret = builder.Configuration["AzureAd:ClientSecret"] ?? "dummy";
 });

builder.Services.AddRazorPages();

// 4. Dependency Injection (Scoped)
var rabbitMqVHost = builder.Configuration["RabbitMQ:VirtualHost"] ?? "/";

builder.Services.AddMassTransit(x =>
{
    x.AddConsumer<RecordingUploadStartedConsumer>();
    x.AddConsumer<RecordingUploadCompletedConsumer>();
    x.AddConsumer<ChangeDeviceStatusConsumer>();
    x.AddConsumer<VectorMatchCompletedConsumer>();

    x.UsingRabbitMq((context, cfg) =>
    {
        cfg.Host(builder.Configuration["RabbitMQ:Host"] ?? "localhost", rabbitMqVHost, h =>
        {
            h.Username(builder.Configuration["RabbitMQ:Username"] ?? "guest");
            h.Password(builder.Configuration["RabbitMQ:Password"] ?? "guest");
        });

        cfg.ReceiveEndpoint("api-recording-upload-events", e =>
        {
            e.UseMessageRetry(r => r.Exponential(5, TimeSpan.FromSeconds(2), TimeSpan.FromSeconds(30), TimeSpan.FromSeconds(5)));
            e.ConfigureConsumer<RecordingUploadStartedConsumer>(context);
            e.ConfigureConsumer<RecordingUploadCompletedConsumer>(context);
        });

        cfg.ReceiveEndpoint("api-device-status-events", e =>
        {
            e.UseMessageRetry(r => r.Exponential(5, TimeSpan.FromSeconds(2), TimeSpan.FromSeconds(30), TimeSpan.FromSeconds(5)));
            e.ConfigureConsumer<ChangeDeviceStatusConsumer>(context);
        });

        cfg.ReceiveEndpoint("api-vector-match-events", e =>
        {
            e.UseMessageRetry(r => r.Exponential(5, TimeSpan.FromSeconds(2), TimeSpan.FromSeconds(30), TimeSpan.FromSeconds(5)));
            e.ConfigureConsumer<VectorMatchCompletedConsumer>(context);
        });
    });
});

builder.Services.AddScoped<INotificationPublisher, NotificationPublisher>();
builder.Services.AddScoped<IMailingService, RabbitMqMailingService>();

builder.Services.AddSmartGuardServices();

var uploadsRootPath = Path.Combine(builder.Environment.ContentRootPath, "uploads");
Directory.CreateDirectory(uploadsRootPath);
Directory.CreateDirectory(Path.Combine(uploadsRootPath, "images"));
Directory.CreateDirectory(Path.Combine(uploadsRootPath, "reports"));

builder.Services.Configure<FileStorageOptions>(o =>
{
    o.UploadsRootPath = uploadsRootPath;
    o.UrlPrefix = "/uploads";
    o.ImagesSubfolder = "images";
    o.ReportsSubfolder = "reports";
});

builder.Services.Configure<ArchiveOptions>(builder.Configuration.GetSection("Archive"));

var redisConfiguration = builder.Configuration["Redis:Configuration"];
if (!string.IsNullOrWhiteSpace(redisConfiguration))
{
    builder.Services.AddStackExchangeRedisCache(o => o.Configuration = redisConfiguration);
}
else
{
    builder.Services.AddDistributedMemoryCache();
}

builder.Services.AddGrpc(o => o.Interceptors.Add<InternalTokenInterceptor>());
builder.Services.AddHttpClient();
builder.Services.AddControllers()
    .AddJsonOptions(opts =>
        opts.JsonSerializerOptions.Converters.Add(new UtcDateTimeConverter()));
builder.Services.AddSignalR();
builder.Services.AddOpenApi();
builder.Services.AddSingleton<IStreamRecordingManager, StreamRecordingManager>();
builder.Services.AddSingleton<IWebSocketBridgeManager, WebSocketBridgeManager>();
builder.Services.AddHostedService<ReportsSchedulerHostedService>();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Version = "v1",
        Title = "SmartGuard API",
        Description = "API for managing devices and recordings in the SmartGuard application"
    });

    // Add JWT Authentication to Swagger
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

var app = builder.Build();

app.UseMiddleware<ExceptionMiddleware>();

// Seed Database
using (var scope = app.Services.CreateScope())
{
    var seeder = scope.ServiceProvider.GetRequiredService<IDatabaseSeedService>();
    await seeder.SeedAsync();
}

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();

    app.UseSwagger();
    app.UseSwaggerUI();

    app.MapGet("/test/send-notification", async (
        HttpContext httpContext,
        IPublishEndpoint publishEndpoint,
        string? userId,
        string? title,
        string? message,
        bool? sendPush,
        bool? sendEmail,
        string? targetDeviceToken,
        string? emailAddress) =>
    {
        var resolvedUserId = string.IsNullOrWhiteSpace(userId)
            ? httpContext.User.FindFirstValue("UserId")
            : userId.Trim();

        string? payloadUserId = string.IsNullOrWhiteSpace(resolvedUserId) ? null : resolvedUserId;
        string? payloadTargetDeviceToken = string.IsNullOrWhiteSpace(targetDeviceToken) ? null : targetDeviceToken.Trim();
        string? payloadEmailAddress = string.IsNullOrWhiteSpace(emailAddress) ? null : emailAddress.Trim();

        var payload = new
        {
            Type = "Test",
            Title = string.IsNullOrWhiteSpace(title) ? "Test Notification" : title,
            Message = string.IsNullOrWhiteSpace(message) ? "Hello from SmartGuard.API test endpoint" : message,
            UserId = payloadUserId,
            TargetDeviceToken = payloadTargetDeviceToken,
            EmailAddress = payloadEmailAddress,
            SendPush = sendPush ?? false,
            SendEmail = sendEmail ?? false
        };

        await publishEndpoint.Publish<ISendNotificationEvent>(payload);
        return Results.Ok(payload);
    }).RequireAuthorization();
}

app.UseHttpsRedirection();

// /uploads is intentionally NOT served via UseStaticFiles: it contains face images, video
// recordings and PDF reports, which must go through an authorized endpoint (FilesController.View,
// ReportsController.Download) rather than being publicly servable by URL.

app.UseWebSockets();

app.UseCors("AllowAll");

app.UseStaticFiles();

app.UseAuthentication();
app.UseIdentityServer();
app.UseAuthorization();

app.MapRazorPages();
app.MapControllers().RequireAuthorization();

app.MapHub<CameraHub>("/hub/camera");
app.MapGrpcService<VectorMatchingGrpcService>();

app.Run();
