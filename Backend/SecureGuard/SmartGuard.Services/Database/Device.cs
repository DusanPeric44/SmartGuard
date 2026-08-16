using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartGuard.Services.Database
{
    public class Device
    {
        [Key]
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public string MacAddress { get; set; } = string.Empty;
        public string ApiKeyHash { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? LastSeenAt { get; set; }
        
        [ForeignKey("DeviceStatus")]
        public int StatusId { get; set; }
        public DeviceStatus DeviceStatus { get; set; } = null!;

        public ICollection<Recording> Recordings { get; set; } = null!;
        public ICollection<FaceDetectionEvent> FaceDetectionEvents { get; set; } = null!;
        public ICollection<Alert> Alerts { get; set; } = null!;
        public ICollection<UserDeviceAccess> UserDeviceAccesses { get; set; } = null!;
        public ICollection<ScheduledRecording> ScheduledRecordings { get; set; } = null!;
    }
}
