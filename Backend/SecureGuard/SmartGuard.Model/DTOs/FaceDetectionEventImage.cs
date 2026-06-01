using System;

namespace SmartGuard.Model.DTOs
{
    public class FaceDetectionEventImage
    {
        public int Id { get; set; }
        public int? DeviceId { get; set; }
        public string Image { get; set; }
        public DateTime Timestamp { get; set; }
        public double? Score { get; set; }
    }
}

