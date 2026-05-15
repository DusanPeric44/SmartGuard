namespace SmartGuard.Model.SearchObjects
{
    public class DeviceSearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public string? Location { get; set; }
        public int? StatusId { get; set; }
    }
}
