namespace SmartGuard.Model.Requests
{
    public class UserDeviceAccessInsertRequest
    {
        public string UserId { get; set; }
        public int DeviceId { get; set; }
        public bool CanStream { get; set; }
        public bool CanDownload { get; set; }
    }

    public class UserDeviceAccessUpdateRequest
    {
        public bool? CanStream { get; set; }
        public bool? CanDownload { get; set; }
    }
}
