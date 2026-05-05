using MassTransit;
using SmartGuard.Model.Events;
using SmartGuard.Notifications.Microservice.Interfaces;

namespace SmartGuard.Notifications.Microservice.Consumers
{
    public class NotificationConsumer : IConsumer<ISendNotificationEvent>
    {
        private readonly IMailingService _mailingService;
        private readonly IFCMService _fcmService;
        private readonly ILogger<NotificationConsumer> _logger;

        public NotificationConsumer(IMailingService mailingService, IFCMService fcmService, ILogger<NotificationConsumer> logger)
        {
            _mailingService = mailingService;
            _fcmService = fcmService;
            _logger = logger;
        }

        public async Task Consume(ConsumeContext<ISendNotificationEvent> context)
        {
            var message = context.Message;
            _logger.LogInformation("Processing notification event: {Title}", message.Title);

            if (message.SendEmail && !string.IsNullOrEmpty(message.EmailAddress))
            {
                await _mailingService.SendEmailAsync(message.EmailAddress, message.Title, message.Message);
            }

            if (message.SendPush && !string.IsNullOrEmpty(message.TargetDeviceToken))
            {
                await _fcmService.SendPushNotificationAsync(message.TargetDeviceToken, message.Title, message.Message);
            }
        }
    }
}
