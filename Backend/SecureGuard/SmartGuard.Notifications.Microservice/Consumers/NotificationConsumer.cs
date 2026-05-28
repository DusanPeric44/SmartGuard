using MassTransit;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Events;
using SmartGuard.Notifications.Microservice.Database;
using SmartGuard.Notifications.Microservice.Database.Entities;
using SmartGuard.Notifications.Microservice.Interfaces;
using SmartGuard.Notifications.Microservice.Services;

namespace SmartGuard.Notifications.Microservice.Consumers
{
    public class NotificationConsumer : IConsumer<ISendNotificationEvent>
    {
        private readonly IMailingService _mailingService;
        private readonly IFCMService _fcmService;
        private readonly NotificationsDbContext _dbContext;
        private readonly INotificationsRealtimePublisher _realtimePublisher;
        private readonly ILogger<NotificationConsumer> _logger;

        public NotificationConsumer(
            IMailingService mailingService,
            IFCMService fcmService,
            NotificationsDbContext dbContext,
            INotificationsRealtimePublisher realtimePublisher,
            ILogger<NotificationConsumer> logger)
        {
            _mailingService = mailingService;
            _fcmService = fcmService;
            _dbContext = dbContext;
            _realtimePublisher = realtimePublisher;
            _logger = logger;
        }

        public async Task Consume(ConsumeContext<ISendNotificationEvent> context)
        {
            var message = context.Message;
            _logger.LogInformation("Processing notification event: {Title}", message.Title);

            var userId = message.UserId?.Trim() ?? string.Empty;
            if (!string.IsNullOrWhiteSpace(userId))
            {
                var entity = new NotificationEntity
                {
                    UserId = userId,
                    Title = message.Title,
                    Text = message.Message,
                    Timestamp = DateTime.UtcNow,
                    IsRead = false
                };

                _dbContext.Notifications.Add(entity);
                await _dbContext.SaveChangesAsync(context.CancellationToken);

                var dto = new Notification
                {
                    Id = entity.Id,
                    UserId = entity.UserId,
                    Title = entity.Title,
                    Text = entity.Text,
                    Timestamp = entity.Timestamp,
                    IsRead = entity.IsRead
                };

                await _realtimePublisher.SendNewNotificationAsync(userId, dto, context.CancellationToken);
            }

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
