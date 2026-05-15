namespace SmartGuard.Model.Interfaces
{
    public interface INotificationPublisher
    {
        Task SendInviteEmailAsync(string email, string role, string temporaryPassword);
    }
}
