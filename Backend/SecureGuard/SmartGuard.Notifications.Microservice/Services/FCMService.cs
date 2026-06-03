using SmartGuard.Notifications.Microservice.Interfaces;
using FirebaseAdmin.Messaging;
using System.Collections.Generic;

namespace SmartGuard.Notifications.Microservice.Services
{
    public class FCMService : IFCMService
    {
        private readonly ILogger<FCMService> _logger;
        private readonly FirebaseMessaging _messaging;

        public FCMService(FirebaseMessaging messaging, ILogger<FCMService> logger)
        {
            _logger = logger;
            _messaging = messaging;
        }

        public async Task SendPushNotificationAsync(string token, string title, string body, IReadOnlyDictionary<string, string>? data = null)
        {
            if (string.IsNullOrWhiteSpace(token))
            {
                return;
            }

            var message = new Message
            {
                Token = token,
                Notification = new Notification
                {
                    Title = title,
                    Body = body
                },
                Data = data == null ? null : new Dictionary<string, string>(data)
            };

            try
            {
                var messageId = await _messaging.SendAsync(message);
                _logger.LogInformation("FCM message sent. MessageId={MessageId}", messageId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending FCM message. Token={Token}", token);
            }
        }
    }
}
