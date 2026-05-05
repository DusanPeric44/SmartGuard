using Microsoft.EntityFrameworkCore;
using SmartGuard.Services.Database;

namespace SmartGuard.Archive.Microservice.Database
{
    public class ArchiveDbContext : DbContext
    {
        public ArchiveDbContext(DbContextOptions<ArchiveDbContext> options) : base(options)
        {
        }

        public DbSet<Recording> Recordings { get; set; }
        public DbSet<ScheduledRecording> ScheduledRecordings { get; set; }
        public DbSet<RecordingStatus> RecordingStatuses { get; set; }
        public DbSet<RecordingType> RecordingTypes { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            // Configure archive specific entities if needed
        }
    }
}
