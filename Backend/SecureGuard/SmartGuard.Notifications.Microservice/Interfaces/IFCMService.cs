namespace SmartGuard.Notifications.Microservice.Interfaces
{
    public interface IFCMService
    {
        Task SendPushNotificationAsync(string token, string title, string body);
    }
}
