using System.ComponentModel.DataAnnotations;

namespace SmartGuard.Services.Database
{
    public class Country
    {
        [Key]
        public int Id { get; set; }
        public string Name { get; set; }
    }
}
