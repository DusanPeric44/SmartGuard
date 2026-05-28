using Microsoft.EntityFrameworkCore;
using SmartGuard.Notifications.Microservice.Database.Entities;

namespace SmartGuard.Notifications.Microservice.Database
{
    public class NotificationsDbContext(DbContextOptions<NotificationsDbContext> options) : DbContext(options)
    {
        public DbSet<NotificationEntity> Notifications => Set<NotificationEntity>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<NotificationEntity>(entity =>
            {
                entity.ToTable("Notifications");
                entity.HasKey(x => x.Id);

                entity.Property(x => x.UserId).IsRequired();
                entity.Property(x => x.Title).IsRequired();
                entity.Property(x => x.Text).IsRequired();

                entity.HasIndex(x => new { x.UserId, x.IsRead });
                entity.HasIndex(x => new { x.UserId, x.Timestamp });
            });
        }
    }
}

