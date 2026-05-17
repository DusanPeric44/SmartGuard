namespace SmartGuard.Model.Events
{
    public interface IRecordingUploadCompletedEvent
    {
        int DeviceId { get; }
        DateTime TimestampUtc { get; }
        string FileName { get; }
        string FileUrl { get; }
        long Size { get; }
        int Duration { get; }
        bool Success { get; }
    }
}
