using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using SmartGuard.Notifications.Microservice.Redis;
using SmartGuard.Notifications.Microservice.Services;
using System.Security.Claims;

namespace SmartGuard.Notifications.Microservice.Hubs
{
    [Authorize]
    public class NotificationsHub(
        IRedisConnectionStore connectionStore,
        INotificationsRealtimePublisher realtimePublisher) : Hub
    {
        public override async Task OnConnectedAsync()
        {
            var userId = Context.User?.FindFirstValue("UserId") ?? string.Empty;
            if (string.IsNullOrWhiteSpace(userId))
            {
                Context.Abort();
                return;
            }

            await connectionStore.AddConnectionAsync(userId, Context.ConnectionId, Context.ConnectionAborted);
            await realtimePublisher.SendUnreadCountAsync(userId, force: true, Context.ConnectionAborted);
            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = Context.User?.FindFirstValue("UserId") ?? string.Empty;
            if (!string.IsNullOrWhiteSpace(userId))
            {
                await connectionStore.RemoveConnectionAsync(userId, Context.ConnectionId, Context.ConnectionAborted);
            }

            await base.OnDisconnectedAsync(exception);
        }
    }
}

