namespace SmartGuard.Model.Requests
{
    public class UserNotificationPreferenceInsertRequest
    {
        public string UserId { get; set; }
        public int? PersonId { get; set; }
        public int? AlertTypeId { get; set; }
        public bool ReceivePush { get; set; }
        public bool ReceiveEmail { get; set; }
    }

    public class UserNotificationPreferenceUpdateRequest
    {
        public bool? ReceivePush { get; set; }
        public bool? ReceiveEmail { get; set; }
    }
}
