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
        private readonly RoleManager<ApplicationRole> _roleManager;

        public DatabaseSeedService(
            SmartGuardContext context,
            UserManager<ApplicationUser> userManager,
            RoleManager<ApplicationRole> roleManager)
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
                    await _roleManager.CreateAsync(new ApplicationRole(roleName));
                }
            }

            // 3. Seed Default Users
            await SeedUserAsync("admin@smartguard.com", "Admin123!", "Admin", "Admin", "SmartGuard", "Admin");
            await SeedUserAsync("homeowner@smartguard.com", "HomeOwner123!", "HomeOwner", "John", "Doe", "HomeOwner");
            await SeedUserAsync("viewer@smartguard.com", "Viewer123!", "Viewer", "Jane", "Smith", "Viewer");

            // 4. Seed Alert Statuses
            string[] alertStatuses = { "Pending", "Confirmed", "Dismissed", "Resolved" };
            foreach (var status in alertStatuses)
            {
                if (!await _context.AlertStatuses.AnyAsync(x => x.Name == status))
                {
                    _context.AlertStatuses.Add(new AlertStatus { Name = status });
                }
            }

            // 5. Seed Alert Types
            string[] alertTypes = { "IntruderDetected" };
            foreach (var type in alertTypes)
            {
                if (!await _context.AlertTypes.AnyAsync(x => x.Name == type))
                {
                    _context.AlertTypes.Add(new AlertType { Name = type });
                }
            }

            // 6. Seed Recording Statuses
            string[] recordingStatuses = { "Pending", "Uploading", "Completed", "Failed", "Archived" };
            foreach (var status in recordingStatuses)
            {
                if (!await _context.RecordingStatuses.AnyAsync(x => x.Name == status))
                {
                    _context.RecordingStatuses.Add(new RecordingStatus { Name = status });
                }
            }

            // 7. Seed Recording Types
            string[] recordingTypes = { "Motion", "FaceDetected", "Manual" };
            foreach (var type in recordingTypes)
            {
                if (!await _context.RecordingTypes.AnyAsync(x => x.Name == type))
                {
                    _context.RecordingTypes.Add(new RecordingType { Name = type });
                }
            }

            // 8. Seed Device Statuses
            string[] deviceStatuses = { "Online", "Offline", "Recording", "Maintenance" };
            foreach (var status in deviceStatuses)
            {
                if (!await _context.DeviceStatuses.AnyAsync(x => x.Name == status))
                {
                    _context.DeviceStatuses.Add(new DeviceStatus { Name = status });
                }
            }

            // 9. Seed Report Statuses
            string[] reportStatuses = { "Generating", "Generated", "Failed" };
            foreach (var status in reportStatuses)
            {
                if (!await _context.ReportStatuses.AnyAsync(x => x.Name == status))
                {
                    _context.ReportStatuses.Add(new ReportStatus { Name = status });
                }
            }

            // 10. Seed Report Types
            string[] reportTypes = { "MonthlyAlarm", "WeeklySummary", "SecurityActivity" };
            foreach (var type in reportTypes)
            {
                if (!await _context.ReportTypes.AnyAsync(x => x.Name == type))
                {
                    _context.ReportTypes.Add(new ReportType { Name = type });
                }
            }

            await _context.SaveChangesAsync();
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
