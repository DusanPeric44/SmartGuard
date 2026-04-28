using System.ComponentModel.DataAnnotations;

namespace SmartGuard.Services.Database
{
    public class DeviceStatus
    {
        [Key]
        public int Id { get; set; }
        public string Name { get; set; }
    }
}
