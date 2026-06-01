using System.ComponentModel.DataAnnotations;

namespace SmartGuard.Model.Requests
{
    public class MotionDetectionDetectRequest
    {
        [Required]
        public int DeviceId { get; set; }
    }
}

