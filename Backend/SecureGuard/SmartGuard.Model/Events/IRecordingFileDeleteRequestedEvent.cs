namespace SmartGuard.Model.Events
{
    public interface IRecordingFileDeleteRequestedEvent
    {
        int RecordingId { get; }
        string FileUrl { get; }
        string FileName { get; }
        DateTime RequestedAtUtc { get; }
    }
}

