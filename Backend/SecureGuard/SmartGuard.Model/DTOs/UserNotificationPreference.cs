namespace SmartGuard.Model.DTOs
{
    public class UserNotificationPreference
    {
        public int Id { get; set; }
        public string UserId { get; set; }
        public int? PersonId { get; set; }
        public KnownPerson Person { get; set; }
        public int? AlertTypeId { get; set; }
        public AlertType AlertType { get; set; }
        public bool ReceivePush { get; set; }
        public bool ReceiveEmail { get; set; }
    }
}
