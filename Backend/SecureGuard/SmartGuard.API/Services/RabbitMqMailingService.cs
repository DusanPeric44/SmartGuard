using MassTransit;
using SmartGuard.Model.Events;
using SmartGuard.Model.Interfaces;

namespace SmartGuard.API.Services
{
    public class RabbitMqMailingService : IMailingService
    {
        private readonly IPublishEndpoint _publishEndpoint;

        public RabbitMqMailingService(IPublishEndpoint publishEndpoint)
        {
            _publishEndpoint = publishEndpoint;
        }

        public async Task SendEmailAsync(string to, string subject, string body)
        {
            await _publishEndpoint.Publish<ISendNotificationEvent>(new
            {
                Type = "GenericEmail",
                Title = subject,
                Message = body,
                UserId = (string?)null,
                TargetDeviceToken = (string?)null,
                EmailAddress = to,
                SendPush = false,
                SendEmail = true
            });
        }
    }
}
