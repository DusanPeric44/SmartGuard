namespace SmartGuard.Model.Requests
{
    public class UserNotificationPreferenceInsertRequest
    {
        public string UserId { get; set; }
        public int? PersonId { get; set; }
        public int? AlertTypeId { get; set; }
        public bool Enabled { get; set; } = true;
    }

    public class UserNotificationPreferenceUpdateRequest
    {
        public bool Enabled { get; set; }
    }
}
