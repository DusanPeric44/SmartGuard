using MassTransit;
using Microsoft.EntityFrameworkCore;
using SmartGuard.Model.Events;
using SmartGuard.Services.Database;

namespace SmartGuard.API.Consumers
{
    public class ChangeDeviceStatusConsumer : IConsumer<IChangeDeviceStatusEvent>
    {
        private readonly SmartGuardContext _context;
        private readonly ILogger<ChangeDeviceStatusConsumer> _logger;

        public ChangeDeviceStatusConsumer(SmartGuardContext context, ILogger<ChangeDeviceStatusConsumer> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task Consume(ConsumeContext<IChangeDeviceStatusEvent> context)
        {
            var message = context.Message;
            if (string.IsNullOrWhiteSpace(message.DeviceId) || string.IsNullOrWhiteSpace(message.StatusName))
            {
                _logger.LogWarning("Invalid device status change event received (DeviceId='{DeviceId}', StatusName='{StatusName}')", message.DeviceId, message.StatusName);
                return;
            }

            Device? device;
            if (int.TryParse(message.DeviceId, out var parsedDeviceId))
            {
                device = await _context.Devices.FirstOrDefaultAsync(x => x.Id == parsedDeviceId, context.CancellationToken);
            }
            else
            {
                device = await _context.Devices.FirstOrDefaultAsync(x => x.MacAddress == message.DeviceId, context.CancellationToken);
            }

            if (device == null)
            {
                _logger.LogWarning("Device not found for status change event (DeviceId='{DeviceId}', StatusName='{StatusName}')", message.DeviceId, message.StatusName);
                return;
            }

            var statusId = await _context.DeviceStatuses
                .Where(x => x.Name == message.StatusName)
                .Select(x => (int?)x.Id)
                .FirstOrDefaultAsync(context.CancellationToken);

            if (statusId == null)
            {
                _logger.LogWarning("DeviceStatus not found for status change event (DeviceId='{DeviceId}', StatusName='{StatusName}')", message.DeviceId, message.StatusName);
                return;
            }

            if (device.StatusId == statusId.Value)
            {
                return;
            }

            device.StatusId = statusId.Value;
            await _context.SaveChangesAsync(context.CancellationToken);

            _logger.LogInformation("Device status updated (DeviceId={DeviceDbId}, StatusName={StatusName})", device.Id, message.StatusName);
        }
    }
}

