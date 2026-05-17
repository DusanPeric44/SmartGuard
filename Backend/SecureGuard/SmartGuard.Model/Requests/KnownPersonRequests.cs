using System.ComponentModel.DataAnnotations;

namespace SmartGuard.Model.Requests
{
    public class KnownPersonInsertRequest
    {
        [Required]
        public string FirstName { get; set; } = string.Empty;
        [Required]
        public string LastName { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;

        public string Picture { get; set; } = string.Empty;
    }

    public class KnownPersonUpdateRequest
    {
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
    }
}
