using System;
using System.ComponentModel.DataAnnotations;

namespace SmartGuard.Model.Requests
{
    public class RecordingInsertRequest
    {
        [Required]
        public string FilePath { get; set; }
        public int Duration { get; set; }
        public long Size { get; set; }
        public DateTime Timestamp { get; set; }
        public int TypeId { get; set; }
        public int StatusId { get; set; }
        public int DeviceId { get; set; }
    }

    public class RecordingUpdateRequest
    {
        public string FilePath { get; set; }
        public int? Duration { get; set; }
        public long? Size { get; set; }
        public DateTime? Timestamp { get; set; }
        public int? TypeId { get; set; }
        public int? StatusId { get; set; }
        public int? DeviceId { get; set; }
        public bool? IsDeleted { get; set; }
    }
}
