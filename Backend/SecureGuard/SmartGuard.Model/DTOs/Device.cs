namespace SmartGuard.Model.DTOs
{
    public class Device
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public string ApiKey { get; set; } = string.Empty;
        public DeviceStatus? DeviceStatus { get; set; }
    }
}
