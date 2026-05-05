namespace SmartGuard.Model.Interfaces
{
    public interface IMailingService
    {
        Task SendEmailAsync(string to, string subject, string body);
    }
}
