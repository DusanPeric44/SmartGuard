using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SmartGuard.Services.Database;

namespace SmartGuard.Services.Database.Configurations
{
    public sealed class FaceDetectionEventConfiguration : IEntityTypeConfiguration<FaceDetectionEvent>
    {
        public void Configure(EntityTypeBuilder<FaceDetectionEvent> builder)
        {
            builder
                .HasMany(x => x.Alerts)
                .WithOne(x => x.LinkedEvent)
                .HasForeignKey(x => x.LinkedEventId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
