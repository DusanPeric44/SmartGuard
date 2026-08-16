using System.ComponentModel.DataAnnotations;

namespace SmartGuard.Model.Requests
{
    public class DeviceStatusUpsertRequest
    {
        [Required]
        public string Name { get; set; }
    }

    public class RecordingTypeUpsertRequest
    {
        [Required]
        public string Name { get; set; }
    }

    public class RecordingStatusUpsertRequest
    {
        [Required]
        public string Name { get; set; }
    }

    public class AlertTypeUpsertRequest
    {
        [Required]
        public string Name { get; set; }
    }

    public class AlertStatusUpsertRequest
    {
        [Required]
        public string Name { get; set; }
    }

    public class ReportTypeUpsertRequest
    {
        [Required]
        public string Name { get; set; }
    }

    public class ReportStatusUpsertRequest
    {
        [Required]
        public string Name { get; set; }
    }
}
