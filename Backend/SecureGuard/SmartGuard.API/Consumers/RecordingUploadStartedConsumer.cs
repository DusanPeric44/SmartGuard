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

            var recordingTypeName = ResolveRecordingTypeName(message.FileName);
            var recordingTypeId = await _context.RecordingTypes
                .Where(x => x.Name == recordingTypeName)
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

        private static string ResolveRecordingTypeName(string fileName)
        {
            var safe = (fileName ?? string.Empty).Trim();
            if (safe.Length == 0) return "Motion";

            var tokens = safe.Split('_', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
            if (tokens.Length >= 3)
            {
                var token = tokens[2];
                if (string.Equals(token, "manual", StringComparison.OrdinalIgnoreCase))
                {
                    return "Manual";
                }

                if (string.Equals(token, "facedetected", StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(token, "face", StringComparison.OrdinalIgnoreCase))
                {
                    return "FaceDetected";
                }

                if (string.Equals(token, "motion", StringComparison.OrdinalIgnoreCase))
                {
                    return "Motion";
                }
            }

            return "Motion";
        }
    }
}
