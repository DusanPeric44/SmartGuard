using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace SmartGuard.Services.Database
{
    public class SmartGuardContext : IdentityDbContext<IdentityUser, IdentityRole, string>
    {
        public SmartGuardContext(DbContextOptions<SmartGuardContext> options) : base(options)
        {
        }

        // DbSets will be added here
        public DbSet<Device> Devices { get; set; }
        public DbSet<DeviceStatus> DeviceStatuses { get; set; }
        public DbSet<Recording> Recordings { get; set; }
        public DbSet<RecordingType> RecordingTypes { get; set; }
        public DbSet<RecordingStatus> RecordingStatuses { get; set; }
        public DbSet<KnownPerson> KnownPersons { get; set; }
        public DbSet<FaceDetectionEvent> FaceDetectionEvents { get; set; }
        public DbSet<Alert> Alerts { get; set; }
        public DbSet<AlertType> AlertTypes { get; set; }
        public DbSet<AlertStatus> AlertStatuses { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<UserNotificationPreference> UserNotificationPreferences { get; set; }
        public DbSet<UserDeviceAccess> UserDeviceAccesses { get; set; }
        public DbSet<AuditLog> AuditLogs { get; set; }
        public DbSet<AIAnalysisResult> AIAnalysisResults { get; set; }
        public DbSet<ScheduledRecording> ScheduledRecordings { get; set; }
        public DbSet<City> Cities { get; set; }
        public DbSet<Country> Countries { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            // Seed Roles
            builder.Entity<IdentityRole>().HasData(
                new IdentityRole { Id = "1", Name = "Admin", NormalizedName = "ADMIN" },
                new IdentityRole { Id = "2", Name = "HomeOwner", NormalizedName = "HOMEOWNER" },
                new IdentityRole { Id = "3", Name = "Viewer", NormalizedName = "VIEWER" }
            );
        }
    }
}