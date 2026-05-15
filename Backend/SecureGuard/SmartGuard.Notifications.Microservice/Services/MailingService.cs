using SmartGuard.Notifications.Microservice.Interfaces;
using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Options;
using MimeKit;
using MimeKit.Text;
using SmartGuard.Model.Options;

namespace SmartGuard.Notifications.Microservice.Services
{
    public class MailingService : IMailingService
    {
        private readonly SmtpOptions _smtpOptions;

        public MailingService(IOptions<SmtpOptions> smtpOptions)
        {
            _smtpOptions = smtpOptions.Value;
        }

        public async Task SendEmailAsync(string to, string subject, string body)
        {
            var host = _smtpOptions.Host;
            var username = _smtpOptions.Username;
            var password = _smtpOptions.Password;
            var fromAddress = _smtpOptions.FromAddress ?? username;
            var fromName = _smtpOptions.FromName;

            if (string.IsNullOrWhiteSpace(host) || string.IsNullOrWhiteSpace(fromAddress))
            {
                throw new InvalidOperationException("SMTP is not configured (Smtp:Host / Smtp:FromAddress).");
            }

            var options = _smtpOptions.UseSsl ? SecureSocketOptions.SslOnConnect : SecureSocketOptions.StartTlsWhenAvailable;

            var message = new MimeMessage();
            message.From.Add(string.IsNullOrWhiteSpace(fromName)
                ? MailboxAddress.Parse(fromAddress)
                : new MailboxAddress(fromName, fromAddress));
            message.To.Add(MailboxAddress.Parse(to));
            message.Subject = subject;
            message.Body = new TextPart(TextFormat.Plain) { Text = body };

            using var client = new SmtpClient();
            await client.ConnectAsync(host, _smtpOptions.Port, options);

            if (!string.IsNullOrWhiteSpace(username))
            {
                await client.AuthenticateAsync(username, password ?? string.Empty);
            }

            await client.SendAsync(message);
            await client.DisconnectAsync(true);
        }
    }
}
