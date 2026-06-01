using MassTransit;
using Microsoft.EntityFrameworkCore;
using SmartGuard.Model.Events;
using SmartGuard.Services.Database;
using SmartGuard.Services.Notifications;

namespace SmartGuard.API.Consumers
{
    public class ChangeDeviceStatusConsumer : IConsumer<IChangeDeviceStatusEvent>
    {
        private readonly SmartGuardContext _context;
        private readonly NotificationDispatchService _notifications;
        private readonly ILogger<ChangeDeviceStatusConsumer> _logger;

        public ChangeDeviceStatusConsumer(
            SmartGuardContext context,
            NotificationDispatchService notifications,
            ILogger<ChangeDeviceStatusConsumer> logger)
        {
            _context = context;
            _notifications = notifications;
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
            if (message.StatusName == "Offline")
            {
                device.LastSeenAt = message.TimestampUtc;
            }
            await _context.SaveChangesAsync(context.CancellationToken);

            _logger.LogInformation("Device status updated (DeviceId={DeviceDbId}, StatusName={StatusName})", device.Id, message.StatusName);

            if (message.StatusName is not ("Online" or "Offline"))
            {
                return;
            }

            var admins = await _notifications.GetAdminUserIdsAsync(context.CancellationToken);
            if (admins.Count == 0)
            {
                return;
            }

            var type = message.StatusName == "Online" ? "DeviceOnline" : "DeviceOffline";
            var title = message.StatusName == "Online"
                ? "SmartGuard - Device online"
                : "SmartGuard - Device offline";

            var deviceName = string.IsNullOrWhiteSpace(device.Name) ? $"Device {device.Id}" : device.Name;
            var timestamp = message.TimestampUtc;
            var body = $"{deviceName} is now {message.StatusName} at {timestamp:O}.";

            await _notifications.PublishSignalRAsync(admins, type, title, body, context.CancellationToken);
        }
    }
}
