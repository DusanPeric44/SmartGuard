using Mapster;
using Microsoft.Extensions.DependencyInjection;
using SmartGuard.Model.Interfaces;
using SmartGuard.Services;
using System.Reflection;

namespace SmartGuard.Services
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddSmartGuardServices(this IServiceCollection services)
        {
            // Mapster
            TypeAdapterConfig.GlobalSettings.Scan(Assembly.GetExecutingAssembly());

            // Core Services
            services.AddScoped<IDevicesService, DevicesService>();
            services.AddScoped<IAlertsService, AlertsService>();
            services.AddScoped<IAuditLogsService, AuditLogsService>();
            services.AddScoped<IFaceDetectionEventsService, FaceDetectionEventsService>();
            services.AddScoped<IMotionDetectionEventsService, MotionDetectionEventsService>();
            services.AddScoped<IKnownPersonsService, KnownPersonsService>();
            services.AddScoped<INotificationsService, NotificationsService>();
            services.AddScoped<IRecordingsService, RecordingsService>();
            services.AddScoped<IScheduledRecordingsService, ScheduledRecordingsService>();
            services.AddScoped<IUserDeviceAccessService, UserDeviceAccessService>();
            services.AddScoped<IUserNotificationPreferencesService, UserNotificationPreferencesService>();
            services.AddScoped<IUserPushTokensService, UserPushTokensService>();
            services.AddScoped<IUsersService, UsersService>();
            services.AddScoped<IReportsService, ReportsService>();
            services.AddScoped<IAuthService, AuthService>();
            services.AddScoped<IDashboardService, DashboardService>();
            services.AddScoped<IDatabaseSeedService, DatabaseSeedService>();
            services.AddScoped<IUserContext, UserContext>();
            services.AddScoped<IFileStorageService, FileStorageService>();
            services.AddScoped<MediaDbMigrationService>();
            
            // Reference Services
            services.AddScoped<IDeviceStatusesService, DeviceStatusesService>();
            services.AddScoped<IRecordingTypesService, RecordingTypesService>();
            services.AddScoped<IRecordingStatusesService, RecordingStatusesService>();
            services.AddScoped<IAlertTypesService, AlertTypesService>();
            services.AddScoped<IAlertStatusesService, AlertStatusesService>();
            services.AddScoped<ICitiesService, CitiesService>();
            services.AddScoped<ICountriesService, CountriesService>();
            
            // Helper Services
            services.AddScoped<ICosineSimilarityService, CosineSimilarityService>();

            return services;
        }
    }
}
