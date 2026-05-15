using Microsoft.AspNetCore.Identity;

namespace SmartGuard.Services.Database
{
    public class ApplicationUser : IdentityUser, ISoftDeletable
    {
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string RegistrationKey { get; set; } = string.Empty;
        public bool IsDeleted { get; set; }
    }
}
