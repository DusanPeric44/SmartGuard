namespace SmartGuard.Model.DTOs
{
    public class Device
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Location { get; set; }
        public string IPAddress { get; set; }
        public string ApiKey { get; set; }
        public int StatusId { get; set; }
        public DeviceStatus DeviceStatus { get; set; }
        public long SDCapacity { get; set; }
        public long FreeSpace { get; set; }
    }
}
