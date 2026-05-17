using MassTransit;
using Microsoft.EntityFrameworkCore;
using SmartGuard.Model.Events;
using SmartGuard.Services.Database;

namespace SmartGuard.API.Consumers
{
    public class RecordingUploadStartedConsumer : IConsumer<IRecordingUploadStartedEvent>
    {
        private readonly SmartGuardContext _context;
        private readonly ILogger<RecordingUploadStartedConsumer> _logger;

        public RecordingUploadStartedConsumer(SmartGuardContext context, ILogger<RecordingUploadStartedConsumer> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task Consume(ConsumeContext<IRecordingUploadStartedEvent> context)
        {
            var message = context.Message;
            var placeholderPath = $"uploading:{message.FileName}";

            var existing = await _context.Recordings
                .AsNoTracking()
                .AnyAsync(x => x.DeviceId == message.DeviceId && x.FilePath == placeholderPath, context.CancellationToken);

            if (existing)
            {
                return;
            }

            var recordingTypeId = await _context.RecordingTypes
                .Where(x => x.Name == "Motion")
                .Select(x => x.Id)
                .FirstAsync(context.CancellationToken);

            var uploadingStatusId = await _context.RecordingStatuses
                .Where(x => x.Name == "Uploading")
                .Select(x => x.Id)
                .FirstAsync(context.CancellationToken);

            _context.Recordings.Add(new Recording
            {
                DeviceId = message.DeviceId,
                Timestamp = message.TimestampUtc,
                StatusId = uploadingStatusId,
                TypeId = recordingTypeId,
                Duration = 0,
                Size = 0,
                FilePath = placeholderPath,
                IsDeleted = false
            });

            await _context.SaveChangesAsync(context.CancellationToken);

            _logger.LogInformation("Recording metadata inserted (DeviceId={DeviceId}, FileName={FileName})", message.DeviceId, message.FileName);
        }
    }
}

