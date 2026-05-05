namespace SmartGuard.Notifications.Microservice.Interfaces
{
    public interface IMailingService
    {
        Task SendEmailAsync(string to, string subject, string body);
    }
}
