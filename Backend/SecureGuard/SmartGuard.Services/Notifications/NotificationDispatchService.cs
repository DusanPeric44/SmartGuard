using MassTransit;
using Microsoft.EntityFrameworkCore;
using SmartGuard.Model.Events;
using SmartGuard.Services.Database;

namespace SmartGuard.Services.Notifications
{
    public class NotificationDispatchService
    {
        public NotificationDispatchService(SmartGuardContext context, IPublishEndpoint publishEndpoint)
        {
            _context = context;
            _publishEndpoint = publishEndpoint;
        }

        private readonly SmartGuardContext _context;
        private readonly IPublishEndpoint _publishEndpoint;

        public async Task<List<string>> GetAdminUserIdsAsync(CancellationToken cancellationToken = default)
        {
            var adminRoleId = await _context.Roles
                .AsNoTracking()
                .Where(r => r.Name == "Admin")
                .Select(r => r.Id)
                .FirstOrDefaultAsync(cancellationToken);

            if (string.IsNullOrWhiteSpace(adminRoleId))
            {
                return new List<string>();
            }

            return await _context.UserRoles
                .AsNoTracking()
                .Where(ur => ur.RoleId == adminRoleId)
                .Select(ur => ur.UserId)
                .Distinct()
                .ToListAsync(cancellationToken);
        }

        public async Task<List<string>> GetDeviceAssignedUserIdsAsync(int deviceId, CancellationToken cancellationToken = default)
        {
            return await _context.UserDeviceAccesses
                .AsNoTracking()
                .Where(x => x.DeviceId == deviceId)
                .Select(x => x.UserId)
                .Distinct()
                .ToListAsync(cancellationToken);
        }

        public async Task PublishSignalRAsync(
            IEnumerable<string> userIds,
            string type,
            string title,
            string message,
            CancellationToken cancellationToken = default)
        {
            var ids = userIds
                .Where(x => !string.IsNullOrWhiteSpace(x))
                .Select(x => x.Trim())
                .Distinct()
                .ToList();

            if (ids.Count == 0)
            {
                return;
            }

            var validUserIds = await _context.Users
                .AsNoTracking()
                .Where(u => !u.IsDeleted && ids.Contains(u.Id))
                .Select(u => u.Id)
                .ToListAsync(cancellationToken);

            foreach (var userId in validUserIds)
            {
                await _publishEndpoint.Publish<ISendNotificationEvent>(new
                {
                    Type = type,
                    Title = title,
                    Message = message,
                    UserId = userId,
                    TargetDeviceToken = (string?)null,
                    EmailAddress = (string?)null,
                    SendPush = false,
                    SendEmail = false
                }, cancellationToken);
            }
        }

        public async Task PublishPushToNonAdminsAsync(
            IEnumerable<string> userIds,
            string type,
            string title,
            string message,
            CancellationToken cancellationToken = default)
        {
            var ids = userIds
                .Where(x => !string.IsNullOrWhiteSpace(x))
                .Select(x => x.Trim())
                .Distinct()
                .ToList();

            if (ids.Count == 0)
            {
                return;
            }

            var adminIds = await GetAdminUserIdsAsync(cancellationToken);
            var adminSet = adminIds.ToHashSet();
            var nonAdminIds = ids.Where(x => !adminSet.Contains(x)).ToList();

            if (nonAdminIds.Count == 0)
            {
                return;
            }

            var tokens = await _context.UserPushTokens
                .AsNoTracking()
                .Where(t => nonAdminIds.Contains(t.UserId))
                .Select(t => t.Token)
                .Distinct()
                .ToListAsync(cancellationToken);

            foreach (var token in tokens)
            {
                if (string.IsNullOrWhiteSpace(token))
                {
                    continue;
                }

                await _publishEndpoint.Publish<ISendNotificationEvent>(new
                {
                    Type = type,
                    Title = title,
                    Message = message,
                    UserId = (string?)null,
                    TargetDeviceToken = token,
                    EmailAddress = (string?)null,
                    SendPush = true,
                    SendEmail = false
                }, cancellationToken);
            }
        }
    }
}
