using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SmartGuard.Services.Database;

namespace SmartGuard.Services.Database.Configurations
{
    public sealed class KnownPersonConfiguration : IEntityTypeConfiguration<KnownPerson>
    {
        public void Configure(EntityTypeBuilder<KnownPerson> builder)
        {
            builder
                .HasIndex(x => x.FaceId)
                .IsUnique()
                .HasFilter("[FaceId] IS NOT NULL");

            builder
                .Property(x => x.CreatedAt)
                .HasDefaultValueSql("GETUTCDATE()");

            builder
                .HasMany(x => x.FaceDetectionEvents)
                .WithOne(x => x.Person)
                .HasForeignKey(x => x.PersonId)
                .OnDelete(DeleteBehavior.Cascade);

            builder
                .HasMany(x => x.UserNotificationPreferences)
                .WithOne(x => x.Person)
                .HasForeignKey(x => x.PersonId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
