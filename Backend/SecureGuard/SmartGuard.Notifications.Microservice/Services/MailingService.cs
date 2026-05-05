using SmartGuard.Notifications.Microservice.Interfaces;
using MailKit.Net.Smtp;
using MimeKit;

namespace SmartGuard.Notifications.Microservice.Services
{
    public class MailingService : IMailingService
    {
        private readonly IConfiguration _config;

        public MailingService(IConfiguration config)
        {
            _config = config;
        }

        public async Task SendEmailAsync(string to, string subject, string body)
        {
            // Skeleton implementation
            Console.WriteLine($"Sending email to {to}: {subject}");
            await Task.CompletedTask;
        }
    }
}
