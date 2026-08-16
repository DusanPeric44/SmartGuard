using MassTransit;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using SmartGuard.Archive.Microservice.Consumers;
using SmartGuard.Archive.Microservice.Database;
using SmartGuard.Model.Interfaces;
using SmartGuard.Services;
using SmartGuard.Services.Database;
using System.Text;
using Xabe.FFmpeg;
using Xabe.FFmpeg.Downloader;

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
builder.Services.AddControllers();
builder.Services.AddOpenApi();
builder.Services.AddHttpClient();

var jwtSettings = builder.Configuration.GetSection("Jwt");
var jwtSecret = jwtSettings["Secret"];
if (string.IsNullOrWhiteSpace(jwtSecret) || jwtSecret.Length < 32)
{
    throw new InvalidOperationException(
        "Jwt:Secret is not configured or is too short (minimum 32 characters). " +
        "Set the JWT_SECRET environment variable or Jwt:Secret in configuration before starting the Archive microservice.");
}
var jwtSecretKey = Encoding.ASCII.GetBytes(jwtSecret);

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
        IssuerSigningKey = new SymmetricSecurityKey(jwtSecretKey),
        ValidateIssuer = true,
        ValidIssuer = jwtSettings["Issuer"],
        ValidateAudience = true,
        ValidAudience = jwtSettings["Audience"],
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
    };
});

// Add DbContext
builder.Services.AddDbContext<ArchiveDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("ArchiveDatabase")));

// Read-only access to the main SmartGuard database (Devices/UserDeviceAccesses) for authorization checks
builder.Services.AddDbContext<SmartGuardContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("MainDatabase")));
builder.Services.AddScoped<IDeviceAccessService, DeviceAccessService>();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IUserContext, UserContext>();

// Add MassTransit
var rabbitMqVHost = builder.Configuration["RabbitMQ:VirtualHost"] ?? "/";

builder.Services.AddMassTransit(x =>
{
    x.AddConsumer<RecordingConsumer>();
    x.AddConsumer<RecordingFileDeleteRequestedConsumer>();

    x.UsingRabbitMq((context, cfg) =>
    {
        cfg.Host(builder.Configuration["RabbitMQ:Host"] ?? "localhost", rabbitMqVHost, h =>
        {
            h.Username(builder.Configuration["RabbitMQ:Username"] ?? "guest");
            h.Password(builder.Configuration["RabbitMQ:Password"] ?? "guest");
        });

        cfg.ReceiveEndpoint("archive-service", e =>
        {
            e.ConfigureConsumer<RecordingConsumer>(context);
            e.ConfigureConsumer<RecordingFileDeleteRequestedConsumer>(context);
        });
    });
});

var ffmpegPath = Path.Combine(builder.Environment.ContentRootPath, "ffmpeg");
Directory.CreateDirectory(ffmpegPath);
await FFmpegDownloader.GetLatestVersion(FFmpegVersion.Official, ffmpegPath);
FFmpeg.SetExecutablesPath(ffmpegPath);

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.UseCors("AllowAll");

var uploadsPath = Path.Combine(builder.Environment.ContentRootPath, "uploads");
if (!Directory.Exists(uploadsPath))
{
    Directory.CreateDirectory(uploadsPath);
}

var videosPath = Path.Combine(uploadsPath, "videos");
if (!Directory.Exists(videosPath))
{
    Directory.CreateDirectory(videosPath);
}

// Video recordings are private content and must not be publicly servable by URL - they are
// streamed only via the authorized VideoArchiveController.Download endpoint.

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers().RequireAuthorization();

app.Run();
