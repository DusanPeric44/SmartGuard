using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using MassTransit;
using SmartGuard.Services;
using SmartGuard.Services.Database;
using SmartGuard.Model.Interfaces;
using Microsoft.OpenApi;
using SmartGuard.API.Middleware;
using SmartGuard.API.Hubs;
using SmartGuard.API.Services;
using SmartGuard.Model.Options;
using Microsoft.AspNetCore.StaticFiles;
using Microsoft.Extensions.FileProviders;
using SmartGuard.API.Consumers;

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
builder.Services.AddIdentityCore<ApplicationUser>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequireLowercase = true;
    options.Password.RequireNonAlphanumeric = true;
    options.Password.RequireUppercase = true;
    options.Password.RequiredLength = 6;
    options.User.RequireUniqueEmail = true;
})
.AddRoles<IdentityRole>()
.AddEntityFrameworkStores<SmartGuardContext>()
.AddDefaultTokenProviders();

builder.Services.AddHttpContextAccessor();
builder.Services.AddSingleton<AuditLogChannel>();
builder.Logging.Services.AddSingleton<ILoggerProvider, AuditLoggerProvider>();
builder.Services.AddHostedService<AuditLoggerBackgroundWriter>();

// 3. Authentication Configuration
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
        ValidateLifetime = true
    };
})
 .AddGoogle(options =>
 {
     options.ClientId = builder.Configuration["Google:ClientId"] ?? "dummy";
     options.ClientSecret = builder.Configuration["Google:ClientSecret"] ?? "dummy";
 })
 .AddMicrosoftAccount(options =>
 {
     options.ClientId = builder.Configuration["AzureAd:ClientId"] ?? "dummy";
     options.ClientSecret = builder.Configuration["AzureAd:ClientSecret"] ?? "dummy";
 });

// 4. Dependency Injection (Scoped)
builder.Services.AddMassTransit(x =>
{
    x.AddConsumer<RecordingUploadStartedConsumer>();
    x.AddConsumer<RecordingUploadCompletedConsumer>();
    x.AddConsumer<ChangeDeviceStatusConsumer>();

    x.UsingRabbitMq((context, cfg) =>
    {
        cfg.Host(builder.Configuration["RabbitMQ:Host"] ?? "localhost", "/", h =>
        {
            h.Username(builder.Configuration["RabbitMQ:Username"] ?? "guest");
            h.Password(builder.Configuration["RabbitMQ:Password"] ?? "guest");
        });

        cfg.ReceiveEndpoint("api-recording-upload-events", e =>
        {
            e.ConfigureConsumer<RecordingUploadStartedConsumer>(context);
            e.ConfigureConsumer<RecordingUploadCompletedConsumer>(context);
        });

        cfg.ReceiveEndpoint("api-device-status-events", e =>
        {
            e.ConfigureConsumer<ChangeDeviceStatusConsumer>(context);
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

var redisConfiguration = builder.Configuration["Redis:Configuration"];
if (!string.IsNullOrWhiteSpace(redisConfiguration))
{
    builder.Services.AddStackExchangeRedisCache(o => o.Configuration = redisConfiguration);
}
else
{
    builder.Services.AddDistributedMemoryCache();
}

builder.Services.AddControllers();
builder.Services.AddSignalR();
builder.Services.AddOpenApi();
builder.Services.AddSingleton<IWebSocketBridgeManager, WebSocketBridgeManager>();
builder.Services.AddHostedService<MediaDbMigrationHostedService>();
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
}

app.UseHttpsRedirection();

var uploadsStaticFileContentTypes = new FileExtensionContentTypeProvider();
uploadsStaticFileContentTypes.Mappings[".webp"] = "image/webp";
uploadsStaticFileContentTypes.Mappings[".pdf"] = "application/pdf";

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(uploadsRootPath),
    RequestPath = "/uploads",
    ContentTypeProvider = uploadsStaticFileContentTypes,
});

app.UseWebSockets();

app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers().RequireAuthorization();

app.MapHub<CameraHub>("/hub/camera");

app.Run();
