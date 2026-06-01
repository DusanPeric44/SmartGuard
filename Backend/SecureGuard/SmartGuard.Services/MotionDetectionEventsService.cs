using MassTransit;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Logging;
using SmartGuard.Model.Events;
using SmartGuard.Model.Interfaces;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class MotionDetectionEventsService : IMotionDetectionEventsService
    {
        private static readonly TimeSpan CooldownTtl = TimeSpan.FromSeconds(30);

        private readonly SmartGuardContext _context;
        private readonly IDistributedCache _cache;
        private readonly IPublishEndpoint _publishEndpoint;
        private readonly ILogger<MotionDetectionEventsService> _logger;

        public MotionDetectionEventsService(
            SmartGuardContext context,
            IDistributedCache cache,
            IPublishEndpoint publishEndpoint,
            ILogger<MotionDetectionEventsService> logger)
        {
            _context = context;
            _cache = cache;
            _publishEndpoint = publishEndpoint;
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

            if (device == null || device.ApiKey != deviceToken)
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
            var body = $"Motion detected on {deviceName} at {timestamp:O}.";

            var tokens = await _context.UserPushTokens
                .AsNoTracking()
                .Select(x => x.Token)
                .ToListAsync();

            var anyPublished = false;
            foreach (var token in tokens.Distinct())
            {
                if (string.IsNullOrWhiteSpace(token)) continue;

                anyPublished = true;
                await _publishEndpoint.Publish<ISendNotificationEvent>(new
                {
                    Title = title,
                    Message = body,
                    UserId = (string?)null,
                    TargetDeviceToken = token,
                    EmailAddress = (string?)null,
                    SendPush = true,
                    SendEmail = false
                });
            }

            await _cache.SetStringAsync(
                cooldownKey,
                "1",
                new DistributedCacheEntryOptions { AbsoluteExpirationRelativeToNow = CooldownTtl });

            _logger.LogInformation("Motion event processed (DeviceId={DeviceId}, PushPublished={PushPublished})", deviceId, anyPublished);

            return false;
        }
    }
}
