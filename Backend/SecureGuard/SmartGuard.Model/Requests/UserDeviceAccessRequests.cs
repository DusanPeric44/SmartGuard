using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace SmartGuard.Model.Requests
{
    public class UserDeviceAccessInsertRequest
    {
        [Range(1, int.MaxValue)]
        public int DeviceId { get; set; }

        [Required]
        [MinLength(1)]
        public List<string> UserIds { get; set; } = new();
    }

    public class UserDeviceAccessUpdateRequest
    {
        public bool? CanStream { get; set; }
        public bool? CanDownload { get; set; }
    }
}
