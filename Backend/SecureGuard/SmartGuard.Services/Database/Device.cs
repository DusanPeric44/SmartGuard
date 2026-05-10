using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartGuard.Services.Database
{
    public class Device
    {
        [Key]
        public int Id { get; set; }
        public string Name { get; set; }
        public string Location { get; set; }
        public string IPAddress { get; set; }
        public string MacAddress { get; set; }
        public string ApiKey { get; set; }
        
        [ForeignKey("DeviceStatus")]
        public int StatusId { get; set; }
        public DeviceStatus DeviceStatus { get; set; }

        public long SDCapacity { get; set; }
        public long FreeSpace { get; set; }

        public ICollection<Recording> Recordings { get; set; }
        public ICollection<FaceDetectionEvent> FaceDetectionEvents { get; set; }
        public ICollection<Alert> Alerts { get; set; }
        public ICollection<UserDeviceAccess> UserDeviceAccesses { get; set; }
        public ICollection<ScheduledRecording> ScheduledRecordings { get; set; }
    }
}
