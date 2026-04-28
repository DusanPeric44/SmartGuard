namespace SmartGuard.Model.DTOs
{
    public class UserDeviceAccess
    {
        public int Id { get; set; }
        public string UserId { get; set; }
        public int DeviceId { get; set; }
        public Device Device { get; set; }
        public bool CanStream { get; set; }
        public bool CanDownload { get; set; }
    }
}
