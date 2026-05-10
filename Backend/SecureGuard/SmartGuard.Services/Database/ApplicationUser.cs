using Microsoft.AspNetCore.Identity;

namespace SmartGuard.Services.Database
{
    public class ApplicationUser : IdentityUser
    {
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string RegistrationKey { get; set; } = string.Empty;
    }
}
