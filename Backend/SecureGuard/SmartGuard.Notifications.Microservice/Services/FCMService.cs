using SmartGuard.Notifications.Microservice.Interfaces;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;

namespace SmartGuard.Notifications.Microservice.Services
{
    public class FCMService : IFCMService
    {
        public async Task SendPushNotificationAsync(string token, string title, string body)
        {
            // Skeleton implementation
            Console.WriteLine($"Sending push notification to {token}: {title}");
            await Task.CompletedTask;
        }
    }
}
