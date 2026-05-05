using MassTransit;
using SmartGuard.Model.Events;
using SmartGuard.Archive.Microservice.Database;

namespace SmartGuard.Archive.Microservice.Consumers
{
    public class RecordingConsumer : IConsumer<IRecordingCreatedEvent>
    {
        private readonly ArchiveDbContext _context;
        private readonly ILogger<RecordingConsumer> _logger;

        public RecordingConsumer(ArchiveDbContext context, ILogger<RecordingConsumer> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task Consume(ConsumeContext<IRecordingCreatedEvent> context)
        {
            var message = context.Message;
            _logger.LogInformation("Recording created event received for ID: {Id}", message.RecordingId);

            // Logic to prepare for archiving, e.g., setting up storage space
            // Or notifying other services
            
            await Task.CompletedTask;
        }
    }
}
