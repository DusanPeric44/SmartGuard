using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SmartGuard.Model.Interfaces;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class DatabaseSeedService : IDatabaseSeedService
    {
        private readonly SmartGuardContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<IdentityRole> _roleManager;

        public DatabaseSeedService(
            SmartGuardContext context,
            UserManager<ApplicationUser> userManager,
            RoleManager<IdentityRole> roleManager)
        {
            _context = context;
            _userManager = userManager;
            _roleManager = roleManager;
        }

        public async Task SeedAsync()
        {
            // 1. Automatic Migration
            if ((await _context.Database.GetPendingMigrationsAsync()).Any())
            {
                await _context.Database.MigrateAsync();
            }

            // 2. Seed Roles
            string[] roleNames = { "Admin", "HomeOwner", "Viewer" };
            foreach (var roleName in roleNames)
            {
                var roleExist = await _roleManager.RoleExistsAsync(roleName);
                if (!roleExist)
                {
                    await _roleManager.CreateAsync(new IdentityRole(roleName));
                }
            }

            // 3. Seed Default Users
            await SeedUserAsync("admin@smartguard.com", "Admin123!", "Admin", "Admin", "SmartGuard", "Admin");
            await SeedUserAsync("homeowner@smartguard.com", "HomeOwner123!", "HomeOwner", "John", "Doe", "HomeOwner");
            await SeedUserAsync("viewer@smartguard.com", "Viewer123!", "Viewer", "Jane", "Smith", "Viewer");
        }

        private async Task SeedUserAsync(string email, string password, string userName, string firstName, string lastName, string role)
        {
            var user = await _userManager.FindByEmailAsync(email);
            if (user == null)
            {
                var newUser = new ApplicationUser
                {
                    UserName = email,
                    Email = email,
                    FirstName = firstName,
                    LastName = lastName,
                    EmailConfirmed = true,
                    RegistrationKey = Guid.NewGuid().ToString()
                };

                var createPowerUser = await _userManager.CreateAsync(newUser, password);
                if (createPowerUser.Succeeded)
                {
                    await _userManager.AddToRoleAsync(newUser, role);
                }
            }
        }
    }
}
