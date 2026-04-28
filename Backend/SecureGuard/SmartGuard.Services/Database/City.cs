using System.ComponentModel.DataAnnotations;

namespace SmartGuard.Services.Database
{
    public class City
    {
        [Key]
        public int Id { get; set; }
        public string Name { get; set; }
        public int CountryId { get; set; }
        public Country Country { get; set; }
    }
}
