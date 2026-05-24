using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SmartGuard.Services.Database;

namespace SmartGuard.Services.Database.Configurations
{
    public sealed class ReportConfiguration : IEntityTypeConfiguration<Report>
    {
        public void Configure(EntityTypeBuilder<Report> builder)
        {
            builder
                .HasIndex(x => new { x.TypeId, x.PeriodStartUtc, x.PeriodEndUtc })
                .IsUnique();
        }
    }
}
