using Mapster;
using Microsoft.AspNetCore.Identity;
using SmartGuard.Model.DTOs;

namespace SmartGuard.Services.Database
{
    public class ApplicationUser : IdentityUser, ISoftDeletable, IRegister
    {
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string RegistrationKey { get; set; } = string.Empty;
        public bool IsDeleted { get; set; }
        public ICollection<ApplicationUserRole> UserRoles { get; set; } = null!;

        public void Register(TypeAdapterConfig config)
        {
            config.NewConfig<ApplicationUser, UserDto>()
                  .Map(dest => dest.Role, 
                       source => source.UserRoles.FirstOrDefault() != null 
                                 ? source.UserRoles.FirstOrDefault()!.Role.Name
                                 : string.Empty );
        }
    }
}
