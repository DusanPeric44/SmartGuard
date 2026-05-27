namespace SmartGuard.Model.Events
{
    public interface IVectorMatchRequestedEvent
    {
        int FaceDetectionEventId { get; }
        int DeviceId { get; }
    }
}
