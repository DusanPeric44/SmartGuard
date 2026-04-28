namespace SmartGuard.Model.SearchObjects
{
    public class UserDeviceAccessSearchObject : BaseSearchObject
    {
        public string UserId { get; set; }
        public int? DeviceId { get; set; }
    }
}
