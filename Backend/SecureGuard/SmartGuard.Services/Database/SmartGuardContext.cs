using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace SmartGuard.Services.Database
{
    public class SmartGuardContext : IdentityDbContext<ApplicationUser, IdentityRole, string>
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
        public DbSet<UserPushToken> UserPushTokens { get; set; }
        public DbSet<AuditLog> AuditLogs { get; set; }
        public DbSet<Report> Reports { get; set; }
        public DbSet<ReportType> ReportTypes { get; set; }
        public DbSet<ReportStatus> ReportStatuses { get; set; }
        public DbSet<ScheduledRecording> ScheduledRecordings { get; set; }
        public DbSet<City> Cities { get; set; }
        public DbSet<Country> Countries { get; set; }
        public DbSet<RefreshToken> RefreshTokens { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            builder.Entity<KnownPerson>()
                .HasIndex(x => x.FaceId)
                .IsUnique()
                .HasFilter("[FaceId] IS NOT NULL");

            builder.Entity<UserNotificationPreference>()
                .Property(x => x.Enabled)
                .HasDefaultValue(true);

            builder.Entity<Alert>()
                .Property(x => x.CreatedAt)
                .HasDefaultValueSql("GETUTCDATE()");

            builder.Entity<Device>()
                .Property(x => x.CreatedAt)
                .HasDefaultValueSql("GETUTCDATE()");

            builder.Entity<KnownPerson>()
                .Property(x => x.CreatedAt)
                .HasDefaultValueSql("GETUTCDATE()");

            builder.Entity<Report>()
                .HasIndex(x => new { x.TypeId, x.PeriodStartUtc, x.PeriodEndUtc })
                .IsUnique();
        }
    }
}
