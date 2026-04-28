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

    public class CityUpsertRequest
    {
        [Required]
        public string Name { get; set; }
        public int CountryId { get; set; }
    }

    public class CountryUpsertRequest
    {
        [Required]
        public string Name { get; set; }
    }
}
