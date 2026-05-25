using Microsoft.AspNetCore.Identity;

namespace SmartGuard.Services.Database
{
    public class ApplicationUserRole : IdentityUserRole<string>
    {
        public ApplicationUser User { get; set; } = null!;
        public ApplicationRole Role { get; set; } = null!;
    }
}
