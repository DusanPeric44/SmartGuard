using MassTransit;
using Microsoft.EntityFrameworkCore;
using SmartGuard.Model.Events;
using SmartGuard.Services.Database;

namespace SmartGuard.API.Consumers
{
    public class RecordingUploadCompletedConsumer : IConsumer<IRecordingUploadCompletedEvent>
    {
        private readonly SmartGuardContext _context;
        private readonly ILogger<RecordingUploadCompletedConsumer> _logger;

        public RecordingUploadCompletedConsumer(SmartGuardContext context, ILogger<RecordingUploadCompletedConsumer> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task Consume(ConsumeContext<IRecordingUploadCompletedEvent> context)
        {
            var message = context.Message;
            var placeholderPath = $"uploading:{message.FileName}";

            var recording = await _context.Recordings
                .FirstOrDefaultAsync(x => x.DeviceId == message.DeviceId && x.FilePath == placeholderPath, context.CancellationToken);

            if (recording == null)
            {
                _logger.LogWarning("Recording metadata not found for completion (DeviceId={DeviceId}, FileName={FileName})", message.DeviceId, message.FileName);
                return;
            }

            if (message.Success)
            {
                var completedStatusId = await _context.RecordingStatuses
                    .Where(x => x.Name == "Completed")
                    .Select(x => x.Id)
                    .FirstAsync(context.CancellationToken);

                recording.FilePath = message.FileUrl;
                recording.Size = message.Size;
                recording.Duration = message.Duration;
                recording.StatusId = completedStatusId;
            }
            else
            {
                var failedStatusId = await _context.RecordingStatuses
                    .Where(x => x.Name == "Failed")
                    .Select(x => x.Id)
                    .FirstAsync(context.CancellationToken);

                recording.StatusId = failedStatusId;
            }

            await _context.SaveChangesAsync(context.CancellationToken);

            _logger.LogInformation("Recording metadata updated on completion (DeviceId={DeviceId}, FileName={FileName}, Success={Success})", message.DeviceId, message.FileName, message.Success);
        }
    }
}
