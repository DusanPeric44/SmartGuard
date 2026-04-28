using System.ComponentModel.DataAnnotations;

namespace SmartGuard.Services.Database
{
    public class RecordingStatus
    {
        [Key]
        public int Id { get; set; }
        public string Name { get; set; }
    }
}
