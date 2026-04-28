using System;

namespace SmartGuard.Model.DTOs
{
    public class Recording
    {
        public int Id { get; set; }
        public string FilePath { get; set; }
        public int Duration { get; set; }
        public long Size { get; set; }
        public DateTime Timestamp { get; set; }
        public int TypeId { get; set; }
        public RecordingType RecordingType { get; set; }
        public int StatusId { get; set; }
        public RecordingStatus RecordingStatus { get; set; }
        public int DeviceId { get; set; }
        public Device Device { get; set; }
        public bool IsDeleted { get; set; }
    }
}
