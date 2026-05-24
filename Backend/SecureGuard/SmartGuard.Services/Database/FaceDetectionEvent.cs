using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartGuard.Services.Database
{
    public class FaceDetectionEvent
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Device")]
        public int? DeviceId { get; set; }
        public Device? Device { get; set; }

        [ForeignKey("Person")]
        public int? PersonId { get; set; }
        public KnownPerson Person { get; set; }

        public int? FaceId { get; set; }
        public string Image { get; set; }
        public DateTime Timestamp { get; set; }
        public byte[] Embedding { get; set; }

        public ICollection<Alert> Alerts { get; set; }
    }
}
