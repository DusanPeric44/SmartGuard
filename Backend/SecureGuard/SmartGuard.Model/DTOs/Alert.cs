namespace SmartGuard.Model.DTOs
{
    public class Alert
    {
        public int Id { get; set; }
        public int TypeId { get; set; }
        public AlertType AlertType { get; set; }
        public int StatusId { get; set; }
        public AlertStatus AlertStatus { get; set; }
        public string Description { get; set; }
        public int DeviceId { get; set; }
        public Device Device { get; set; }
        public int? LinkedEventId { get; set; }
        public FaceDetectionEvent LinkedEvent { get; set; }
        public string ConfirmedByUserId { get; set; }
        public bool IsDeleted { get; set; }
    }
}
