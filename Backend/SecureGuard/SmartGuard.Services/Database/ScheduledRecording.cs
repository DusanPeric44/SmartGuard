using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartGuard.Services.Database
{
    public class ScheduledRecording
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Device")]
        public int DeviceId { get; set; }
        public Device Device { get; set; }

        public string DaysOfWeek { get; set; } // e.g., "Monday,Tuesday,Wednesday"
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }
        public bool IsActive { get; set; }
    }
}
