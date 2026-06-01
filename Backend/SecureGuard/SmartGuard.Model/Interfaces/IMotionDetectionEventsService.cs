namespace SmartGuard.Model.Interfaces
{
    public interface IMotionDetectionEventsService
    {
        Task<bool> DetectAsync(int deviceId, string deviceToken);
    }
}

