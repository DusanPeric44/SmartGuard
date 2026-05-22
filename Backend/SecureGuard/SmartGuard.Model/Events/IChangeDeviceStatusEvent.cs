namespace SmartGuard.Model.Events
{
    public interface IChangeDeviceStatusEvent
    {
        string DeviceId { get; }
        string StatusName { get; }
        DateTime TimestampUtc { get; }
    }
}

