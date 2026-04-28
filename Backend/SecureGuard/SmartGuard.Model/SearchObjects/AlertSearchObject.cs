namespace SmartGuard.Model.SearchObjects
{
    public class AlertSearchObject : BaseSearchObject
    {
        public int? DeviceId { get; set; }
        public int? TypeId { get; set; }
        public int? StatusId { get; set; }
    }
}
