using System.ComponentModel.DataAnnotations;

namespace SmartGuard.Model.Requests
{
    public class InviteUserRequest
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string Role { get; set; } = string.Empty;
    }
}
