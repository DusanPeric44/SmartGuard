using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.AspNetCore.Identity;

namespace SmartGuard.Services.Database
{
    public class UserDeviceAccess
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("User")]
        public string UserId { get; set; }
        public ApplicationUser User { get; set; }

        [ForeignKey("Device")]
        public int DeviceId { get; set; }
        public Device Device { get; set; }

        public bool CanStream { get; set; }
        public bool CanDownload { get; set; }
    }
}
