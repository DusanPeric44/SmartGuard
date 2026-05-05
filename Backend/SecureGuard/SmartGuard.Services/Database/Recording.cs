using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartGuard.Services.Database
{
    public class Recording : ISoftDeletable
    {
        [Key]
        public int Id { get; set; }
        public string FilePath { get; set; }
        public int Duration { get; set; }
        public long Size { get; set; }
        public DateTime Timestamp { get; set; }

        [ForeignKey("RecordingType")]
        public int TypeId { get; set; }
        public RecordingType RecordingType { get; set; }

        [ForeignKey("RecordingStatus")]
        public int StatusId { get; set; }
        public RecordingStatus RecordingStatus { get; set; }

        [ForeignKey("Device")]
        public int DeviceId { get; set; }
        public Device Device { get; set; }

        public bool IsDeleted { get; set; }
    }
}
