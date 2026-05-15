using Microsoft.Extensions.DependencyInjection;
using SmartGuard.Model.Interfaces;
using SmartGuard.Services;

namespace SmartGuard.Services
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddSmartGuardServices(this IServiceCollection services)
        {
            // Core Services
            services.AddScoped<IDevicesService, DevicesService>();
            services.AddScoped<IAlertsService, AlertsService>();
            services.AddScoped<IAuditLogsService, AuditLogsService>();
            services.AddScoped<IFaceDetectionEventsService, FaceDetectionEventsService>();
            services.AddScoped<IKnownPersonsService, KnownPersonsService>();
            services.AddScoped<INotificationsService, NotificationsService>();
            services.AddScoped<IRecordingsService, RecordingsService>();
            services.AddScoped<IScheduledRecordingsService, ScheduledRecordingsService>();
            services.AddScoped<IUserDeviceAccessService, UserDeviceAccessService>();
            services.AddScoped<IUserNotificationPreferencesService, UserNotificationPreferencesService>();
            services.AddScoped<IUsersService, UsersService>();
            services.AddScoped<IReportsService, ReportsService>();
            services.AddScoped<IAuthService, AuthService>();
            services.AddScoped<IMailingService, MailingService>();
            services.AddScoped<IDatabaseSeedService, DatabaseSeedService>();
            services.AddScoped<IUserContext, UserContext>();
            
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
