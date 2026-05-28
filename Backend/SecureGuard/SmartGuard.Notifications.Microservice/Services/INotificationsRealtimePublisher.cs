using SmartGuard.Model.DTOs;

namespace SmartGuard.Notifications.Microservice.Services
{
    public interface INotificationsRealtimePublisher
    {
        Task SendUnreadCountAsync(string userId, bool force = false, CancellationToken cancellationToken = default);
        Task SendNewNotificationAsync(string userId, Notification notification, CancellationToken cancellationToken = default);
    }
}

