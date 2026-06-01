namespace SmartGuard.Model.Events
{
    public interface ISendNotificationEvent
    {
        string Type { get; }
        string Title { get; }
        string Message { get; }
        string? UserId { get; }
        string? TargetDeviceToken { get; }
        string? EmailAddress { get; }
        bool SendPush { get; }
        bool SendEmail { get; }
    }
}
