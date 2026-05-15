using System;

namespace SmartGuard.Model.DTOs
{
    public class FaceDetectionEvent
    {
        public int Id { get; set; }
        public int DeviceId { get; set; }
        public Device Device { get; set; }
        public int? PersonId { get; set; }
        public KnownPerson Person { get; set; }
        public int? FaceId { get; set; }
        public string Image { get; set; }
        public DateTime Timestamp { get; set; }
        public byte[] Embedding { get; set; }
    }
}
