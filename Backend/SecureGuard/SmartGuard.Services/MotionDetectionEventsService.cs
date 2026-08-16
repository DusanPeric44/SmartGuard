using MassTransit;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Logging;
using SmartGuard.Model.Events;
using SmartGuard.Model.Interfaces;
using SmartGuard.Services.Database;
using SmartGuard.Services.Notifications;
using SmartGuard.Services.Security;

namespace SmartGuard.Services
{
    public class MotionDetectionEventsService : IMotionDetectionEventsService
    {
        private static readonly TimeSpan CooldownTtl = TimeSpan.FromSeconds(30);

        private readonly SmartGuardContext _context;
        private readonly IDistributedCache _cache;
        private readonly NotificationDispatchService _notifications;
        private readonly ILogger<MotionDetectionEventsService> _logger;

        public MotionDetectionEventsService(
            SmartGuardContext context,
            IDistributedCache cache,
            NotificationDispatchService notifications,
            ILogger<MotionDetectionEventsService> logger)
        {
            _context = context;
            _cache = cache;
            _notifications = notifications;
            _logger = logger;
        }

        public async Task<bool> DetectAsync(int deviceId, string deviceToken)
        {
            if (string.IsNullOrWhiteSpace(deviceToken))
            {
                throw new UnauthorizedAccessException();
            }

            var device = await _context.Devices
                .AsNoTracking()
                .SingleOrDefaultAsync(d => d.Id == deviceId);

            if (device == null || !ApiKeyHasher.Verify(deviceToken, device.ApiKeyHash))
            {
                throw new UnauthorizedAccessException();
            }

            var cooldownKey = $"motion-notify:{deviceId}";
            var cooldownExists = await _cache.GetStringAsync(cooldownKey);
            if (!string.IsNullOrWhiteSpace(cooldownExists))
            {
                return true;
            }

            var deviceName = string.IsNullOrWhiteSpace(device.Name) ? $"Device {deviceId}" : device.Name;
            var timestamp = DateTime.UtcNow;

            var title = "SmartGuard - Motion detected";
            var body = $"Motion detected on {deviceName}.";

            var assignedUserIds = await _notifications.GetDeviceAssignedUserIdsAsync(deviceId);
            var adminUserIds = await _notifications.GetAdminUserIdsAsync();
            var recipients = assignedUserIds.Concat(adminUserIds).Distinct().ToList();

            var anySignalr = recipients.Count > 0;
            if (anySignalr)
            {
                await _notifications.PublishSignalRAsync(recipients, "MotionDetected", title, body);
            }

            await _notifications.PublishPushToNonAdminsAsync(recipients, "MotionDetected", title, body);

            await _cache.SetStringAsync(
                cooldownKey,
                "1",
                new DistributedCacheEntryOptions { AbsoluteExpirationRelativeToNow = CooldownTtl });

            _logger.LogInformation("Motion event processed (DeviceId={DeviceId}, SignalRPublished={SignalRPublished})", deviceId, anySignalr);

            return false;
        }
    }
}
