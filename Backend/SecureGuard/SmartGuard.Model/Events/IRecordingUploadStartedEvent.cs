namespace SmartGuard.Model.Events
{
    public interface IRecordingUploadStartedEvent
    {
        int DeviceId { get; }
        DateTime TimestampUtc { get; }
        string FileName { get; }
        string ContentType { get; }
    }
}

