using System;

namespace SmartGuard.Model.DTOs
{
    public class ScheduledRecording
    {
        public int Id { get; set; }
        public int DeviceId { get; set; }
        public Device Device { get; set; }
        public string DaysOfWeek { get; set; }
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }
        public bool IsActive { get; set; }
    }
}
