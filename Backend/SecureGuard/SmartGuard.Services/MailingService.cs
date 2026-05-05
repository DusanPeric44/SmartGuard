using Microsoft.Extensions.Logging;
using SmartGuard.Model.Interfaces;

namespace SmartGuard.Services
{
    public class MailingService : IMailingService
    {
        private readonly ILogger<MailingService> _logger;

        public MailingService(ILogger<MailingService> logger)
        {
            _logger = logger;
        }

        public Task SendEmailAsync(string to, string subject, string body)
        {
            // Mock implementation: just log the email
            _logger.LogInformation("Sending email to {To} with subject '{Subject}' and body '{Body}'", to, subject, body);
            return Task.CompletedTask;
        }
    }
}
