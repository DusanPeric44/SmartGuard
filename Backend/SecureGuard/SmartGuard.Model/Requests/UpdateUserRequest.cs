using System.ComponentModel.DataAnnotations;

namespace SmartGuard.Model.Requests
{
    public class UpdateUserRequest
    {
        public string? FirstName { get; set; } = string.Empty;
        public string? LastName { get; set; } = string.Empty;

        [Required]
        public string Role { get; set; } = string.Empty;
    }
}