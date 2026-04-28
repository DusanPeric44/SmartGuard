namespace SmartGuard.Model.Requests
{
    public class DeviceUpdateRequest
    {
        public string Name { get; set; }
        public string Location { get; set; }
        public string IPAddress { get; set; }
        public string ApiKey { get; set; }
        public int? StatusId { get; set; }
        public long? SDCapacity { get; set; }
        public long? FreeSpace { get; set; }
    }
}
