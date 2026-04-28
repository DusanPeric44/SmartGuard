using System;

namespace SmartGuard.Model.Requests
{
    public class ScheduledRecordingInsertRequest
    {
        public int DeviceId { get; set; }
        public string DaysOfWeek { get; set; }
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }
        public bool IsActive { get; set; }
    }

    public class ScheduledRecordingUpdateRequest
    {
        public string DaysOfWeek { get; set; }
        public TimeSpan? StartTime { get; set; }
        public TimeSpan? EndTime { get; set; }
        public bool? IsActive { get; set; }
    }
}
