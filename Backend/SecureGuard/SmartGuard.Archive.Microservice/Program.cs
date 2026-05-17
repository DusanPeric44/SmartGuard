using MassTransit;
using Microsoft.EntityFrameworkCore;
using SmartGuard.Archive.Microservice.Consumers;
using SmartGuard.Archive.Microservice.Database;
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

// Add DbContext
builder.Services.AddDbContext<ArchiveDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("ArchiveDatabase")));

// Add MassTransit
builder.Services.AddMassTransit(x =>
{
    x.AddConsumer<RecordingConsumer>();
    x.AddConsumer<RecordingFileDeleteRequestedConsumer>();

    x.UsingRabbitMq((context, cfg) =>
    {
        cfg.Host(builder.Configuration["RabbitMQ:Host"] ?? "localhost", "/", h =>
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

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(uploadsPath),
    RequestPath = "/uploads"
});

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(videosPath),
    RequestPath = "/upload/videos"
});

app.UseAuthorization();
app.MapControllers();

app.Run();
