namespace SmartGuard.Model.Events
{
    public interface IRecordingCreatedEvent
    {
        int RecordingId { get; }
        string DeviceId { get; }
        DateTime Timestamp { get; }
        string FilePath { get; }
    }
}
