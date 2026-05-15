using System;
using System.ComponentModel.DataAnnotations;

namespace SmartGuard.Model.Requests
{
    public class FaceDetectionEventInsertRequest
    {
        public int DeviceId { get; set; }
        public int? PersonId { get; set; }
        public int? FaceId { get; set; }
        public string Image { get; set; }
        public DateTime Timestamp { get; set; }
        public byte[] Embedding { get; set; }
    }

    public class FaceDetectionEventUpdateRequest
    {
        public int? DeviceId { get; set; }
        public int? PersonId { get; set; }
        public int? FaceId { get; set; }
        public string Image { get; set; }
        public DateTime? Timestamp { get; set; }
        public byte[] Embedding { get; set; }
    }
}
