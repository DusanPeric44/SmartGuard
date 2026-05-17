using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using SmartGuard.Services;

namespace SmartGuard.API.Services
{
    public class MediaDbMigrationHostedService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<MediaDbMigrationHostedService> _logger;

        public MediaDbMigrationHostedService(IServiceProvider serviceProvider, ILogger<MediaDbMigrationHostedService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var migrator = scope.ServiceProvider.GetRequiredService<MediaDbMigrationService>();
                var (eventsMigrated, personsMigrated) = await migrator.MigrateAsync(stoppingToken);

                _logger.LogInformation("Media DB migration complete. FaceDetectionEvents migrated: {EventsMigrated}. KnownPersons migrated: {PersonsMigrated}.",
                    eventsMigrated, personsMigrated);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Media DB migration failed.");
            }
        }
    }
}

