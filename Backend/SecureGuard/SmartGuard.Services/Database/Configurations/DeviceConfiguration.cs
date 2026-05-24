using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SmartGuard.Services.Database;

namespace SmartGuard.Services.Database.Configurations
{
    public sealed class DeviceConfiguration : IEntityTypeConfiguration<Device>
    {
        public void Configure(EntityTypeBuilder<Device> builder)
        {
            builder
                .Property(x => x.CreatedAt)
                .HasDefaultValueSql("GETUTCDATE()");

            builder.HasMany(x => x.Recordings)
                .WithOne(x => x.Device)
                .HasForeignKey(x => x.DeviceId)
                .OnDelete(DeleteBehavior.SetNull);

            builder.HasMany(x => x.FaceDetectionEvents)
                .WithOne(x => x.Device)
                .HasForeignKey(x => x.DeviceId)
                .OnDelete(DeleteBehavior.SetNull);

            builder.HasMany(x => x.Alerts)
                .WithOne(x => x.Device)
                .HasForeignKey(x => x.DeviceId)
                .OnDelete(DeleteBehavior.SetNull);

            builder.HasMany(x => x.UserDeviceAccesses)
                .WithOne(x => x.Device)
                .HasForeignKey(x => x.DeviceId)
                .OnDelete(DeleteBehavior.SetNull);

            builder.HasMany(x => x.ScheduledRecordings)
                .WithOne(x => x.Device)
                .HasForeignKey(x => x.DeviceId)
                .OnDelete(DeleteBehavior.SetNull);


        }
    }
}
