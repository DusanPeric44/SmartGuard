using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Distributed;
using SmartGuard.Model.DTOs;
using SmartGuard.Notifications.Microservice.Database;
using SmartGuard.Notifications.Microservice.Hubs;
using SmartGuard.Notifications.Microservice.Redis;

namespace SmartGuard.Notifications.Microservice.Services
{
    public class NotificationsRealtimePublisher(
        IHubContext<NotificationsHub> hubContext,
        NotificationsDbContext dbContext,
        IRedisConnectionStore connectionStore,
        IDistributedCache cache) : INotificationsRealtimePublisher
    {
        public async Task SendUnreadCountAsync(string userId, bool force = false, CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(userId))
            {
                return;
            }

            var unreadCount = await dbContext.Notifications
                .Where(x => x.UserId == userId && !x.IsRead)
                .CountAsync(cancellationToken);

            var cacheKey = GetUnreadCountKey(userId);
            var cached = await cache.GetStringAsync(cacheKey, cancellationToken);

            if (!force && int.TryParse(cached, out var cachedCount) && cachedCount == unreadCount)
            {
                return;
            }

            await cache.SetStringAsync(
                cacheKey,
                unreadCount.ToString(),
                new DistributedCacheEntryOptions { SlidingExpiration = TimeSpan.FromDays(7) },
                cancellationToken);

            var connections = await connectionStore.GetConnectionsAsync(userId, cancellationToken);
            if (connections.Count == 0)
            {
                return;
            }

            await hubContext.Clients.Clients(connections)
                .SendAsync("NotificationCountChanged", new { unreadCount }, cancellationToken);
        }

        public async Task SendNewNotificationAsync(string userId, Notification notification, CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(userId))
            {
                return;
            }

            var connections = await connectionStore.GetConnectionsAsync(userId, cancellationToken);
            if (connections.Count > 0)
            {
                await hubContext.Clients.Clients(connections)
                    .SendAsync("NewNotification", notification, cancellationToken);
            }

            await SendUnreadCountAsync(userId, force: false, cancellationToken);
        }

        private static string GetUnreadCountKey(string userId) => $"notifications:unread-count:{userId}";
    }
}

