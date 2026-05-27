using System;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;
using SmartGuard.Model.Serialization;

namespace SmartGuard.Model.Requests
{
    public class FaceDetectionVectorDetectRequest
    {
        [Required]
        public int DeviceId { get; set; }

        [Required]
        [JsonConverter(typeof(NumericByteArrayJsonConverter))]
        public byte[] ImageBytes { get; set; }

        [Required]
        public float[] Vector { get; set; }
    }

    public class FaceDetectionEventInsertRequest
    {
        public int DeviceId { get; set; }
        public int? PersonId { get; set; }
        public double? Score { get; set; }
        public string Image { get; set; }
        public DateTime Timestamp { get; set; }
        public byte[] Embedding { get; set; }
    }

    public class FaceDetectionEventUpdateRequest
    {
        public int? DeviceId { get; set; }
        public int? PersonId { get; set; }
        public double? Score { get; set; }
        public string Image { get; set; }
        public DateTime? Timestamp { get; set; }
        public byte[] Embedding { get; set; }
    }
}
