using MassTransit;
using SmartGuard.Model.Events;

namespace SmartGuard.Archive.Microservice.Consumers
{
    public class RecordingFileDeleteRequestedConsumer : IConsumer<IRecordingFileDeleteRequestedEvent>
    {
        private readonly IWebHostEnvironment _environment;
        private readonly ILogger<RecordingFileDeleteRequestedConsumer> _logger;

        public RecordingFileDeleteRequestedConsumer(IWebHostEnvironment environment, ILogger<RecordingFileDeleteRequestedConsumer> logger)
        {
            _environment = environment;
            _logger = logger;
        }

        public Task Consume(ConsumeContext<IRecordingFileDeleteRequestedEvent> context)
        {
            var message = context.Message;

            var safeFileName = Path.GetFileName(message.FileName ?? string.Empty);
            if (string.IsNullOrWhiteSpace(safeFileName))
            {
                _logger.LogWarning("Delete requested with empty FileName (RecordingId={RecordingId}, FileUrl={FileUrl})", message.RecordingId, message.FileUrl);
                return Task.CompletedTask;
            }

            var physicalPath = Path.Combine(_environment.ContentRootPath, "uploads", "videos", safeFileName);
            if (!System.IO.File.Exists(physicalPath))
            {
                _logger.LogInformation("File not found for deletion (RecordingId={RecordingId}, Path={Path})", message.RecordingId, physicalPath);
                return Task.CompletedTask;
            }

            System.IO.File.Delete(physicalPath);
            _logger.LogInformation("File deleted (RecordingId={RecordingId}, Path={Path})", message.RecordingId, physicalPath);

            return Task.CompletedTask;
        }
    }
}

