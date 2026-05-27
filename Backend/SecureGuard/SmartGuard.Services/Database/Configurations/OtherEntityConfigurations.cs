using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SmartGuard.Services.Database;

namespace SmartGuard.Services.Database.Configurations
{
    public sealed class AlertStatusConfiguration : IEntityTypeConfiguration<AlertStatus>
    {
        public void Configure(EntityTypeBuilder<AlertStatus> builder)
        {
        }
    }

    public sealed class AlertTypeConfiguration : IEntityTypeConfiguration<AlertType>
    {
        public void Configure(EntityTypeBuilder<AlertType> builder)
        {
        }
    }

    public sealed class ApplicationUserConfiguration : IEntityTypeConfiguration<ApplicationUser>
    {
        public ApplicationUserConfiguration()
        {
        }

        public void Configure(EntityTypeBuilder<ApplicationUser> builder)
        {
        }
    }

    public sealed class AuditLogConfiguration : IEntityTypeConfiguration<AuditLog>
    {
        public void Configure(EntityTypeBuilder<AuditLog> builder)
        {
        }
    }

    public sealed class CityConfiguration : IEntityTypeConfiguration<City>
    {
        public void Configure(EntityTypeBuilder<City> builder)
        {
        }
    }

    public sealed class CountryConfiguration : IEntityTypeConfiguration<Country>
    {
        public void Configure(EntityTypeBuilder<Country> builder)
        {
        }
    }

    public sealed class DeviceStatusConfiguration : IEntityTypeConfiguration<DeviceStatus>
    {
        public void Configure(EntityTypeBuilder<DeviceStatus> builder)
        {
        }
    }

    public sealed class NotificationConfiguration : IEntityTypeConfiguration<Notification>
    {
        public void Configure(EntityTypeBuilder<Notification> builder)
        {
        }
    }

    public sealed class RecordingConfiguration : IEntityTypeConfiguration<Recording>
    {
        public void Configure(EntityTypeBuilder<Recording> builder)
        {
        }
    }

    public sealed class RecordingStatusConfiguration : IEntityTypeConfiguration<RecordingStatus>
    {
        public void Configure(EntityTypeBuilder<RecordingStatus> builder)
        {
        }
    }

    public sealed class RecordingTypeConfiguration : IEntityTypeConfiguration<RecordingType>
    {
        public void Configure(EntityTypeBuilder<RecordingType> builder)
        {
        }
    }

    public sealed class RefreshTokenConfiguration : IEntityTypeConfiguration<RefreshToken>
    {
        public void Configure(EntityTypeBuilder<RefreshToken> builder)
        {
        }
    }

    public sealed class ReportStatusConfiguration : IEntityTypeConfiguration<ReportStatus>
    {
        public void Configure(EntityTypeBuilder<ReportStatus> builder)
        {
        }
    }

    public sealed class ReportTypeConfiguration : IEntityTypeConfiguration<ReportType>
    {
        public void Configure(EntityTypeBuilder<ReportType> builder)
        {
        }
    }

    public sealed class ScheduledRecordingConfiguration : IEntityTypeConfiguration<ScheduledRecording>
    {
        public void Configure(EntityTypeBuilder<ScheduledRecording> builder)
        {
        }
    }

    public sealed class UserDeviceAccessConfiguration : IEntityTypeConfiguration<UserDeviceAccess>
    {
        public void Configure(EntityTypeBuilder<UserDeviceAccess> builder)
        {
        }
    }

    public sealed class UserPushTokenConfiguration : IEntityTypeConfiguration<UserPushToken>
    {
        public void Configure(EntityTypeBuilder<UserPushToken> builder)
        {
        }
    }
}
