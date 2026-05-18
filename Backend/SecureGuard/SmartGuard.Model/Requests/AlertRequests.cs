using System.ComponentModel.DataAnnotations;

namespace SmartGuard.Model.Requests
{
    public class AlertInsertRequest
    {
        public int TypeId { get; set; }
        public int StatusId { get; set; }
        public string Description { get; set; }
        public int DeviceId { get; set; }
        public int? LinkedEventId { get; set; }
        public string? ConfirmedByUserId { get; set; }
    }

    public class AlertUpdateRequest
    {
        public int? TypeId { get; set; }
        public int? StatusId { get; set; }
        public string Description { get; set; }
        public int? DeviceId { get; set; }
        public int? LinkedEventId { get; set; }
        public string? ConfirmedByUserId { get; set; }
        public string? DismissalReason { get; set; }
        public bool? IsDeleted { get; set; }
    }

    public class AlertDismissRequest
    {
        public string DismissalReason { get; set; }
    }
}
