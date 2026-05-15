namespace SmartGuard.Model.Requests
{
    public class DeviceRegistrationRequest
    {
        public string MacAddress { get; set; } = string.Empty;
        public string RegistrationKey { get; set; } = string.Empty;
    }
}