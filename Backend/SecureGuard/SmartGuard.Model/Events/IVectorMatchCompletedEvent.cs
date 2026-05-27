namespace SmartGuard.Model.Events
{
    public interface IVectorMatchCompletedEvent
    {
        int FaceDetectionEventId { get; }
        int DeviceId { get; }
        bool IsMatched { get; }
        int? MatchedPersonId { get; }
        double BestScore { get; }
    }
}
