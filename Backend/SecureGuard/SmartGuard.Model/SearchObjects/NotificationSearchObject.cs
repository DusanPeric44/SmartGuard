namespace SmartGuard.Model.SearchObjects
{
    public class NotificationSearchObject : BaseSearchObject
    {
        public string UserId { get; set; }
        public bool? IsRead { get; set; }
    }
}
