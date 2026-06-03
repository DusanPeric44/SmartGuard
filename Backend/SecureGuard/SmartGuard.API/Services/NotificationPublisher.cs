using MassTransit;
using SmartGuard.Model.Events;
using SmartGuard.Model.Interfaces;

namespace SmartGuard.API.Services
{
    public class NotificationPublisher : INotificationPublisher
    {
        private readonly IPublishEndpoint _publishEndpoint;

        public NotificationPublisher(IPublishEndpoint publishEndpoint)
        {
            _publishEndpoint = publishEndpoint;
        }

        public async Task SendInviteEmailAsync(string email, string role, string temporaryPassword)
        {
            var title = "SmartGuard - Invitation";
            var message = $"You have been invited to SmartGuard as '{role}'.\n\nTemporary password: {temporaryPassword}\n\nPlease log in and change your password as soon as possible.";

            await _publishEndpoint.Publish<ISendNotificationEvent>(new
            {
                Type = "InviteEmail",
                Title = title,
                Message = message,
                UserId = (string?)null,
                TargetDeviceToken = (string?)null,
                EmailAddress = email,
                SendPush = false,
                SendEmail = true
            });
        }
    }
}
