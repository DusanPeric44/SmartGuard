using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using SmartGuard.Model.Interfaces;

namespace SmartGuard.API.Services
{
    public class ReportsSchedulerHostedService : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;

        public ReportsSchedulerHostedService(IServiceScopeFactory scopeFactory)
        {
            _scopeFactory = scopeFactory;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            using var timer = new PeriodicTimer(TimeSpan.FromMinutes(10));
            while (await timer.WaitForNextTickAsync(stoppingToken))
            {
                await RunOnceAsync(stoppingToken);
            }
        }

        private async Task RunOnceAsync(CancellationToken stoppingToken)
        {
            await using var scope = _scopeFactory.CreateAsyncScope();
            var reportsService = scope.ServiceProvider.GetRequiredService<IReportsService>();

            var now = DateTime.UtcNow;

            if (now.Day == 1)
            {
                var currentMonthStart = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                var previousMonthStart = currentMonthStart.AddMonths(-1);
                await reportsService.GenerateMonthlyAsync(previousMonthStart);
            }

            if (now.DayOfWeek == DayOfWeek.Monday)
            {
                var weekStart = now.Date.AddDays(-7);
                weekStart = DateTime.SpecifyKind(weekStart, DateTimeKind.Utc);
                await reportsService.GenerateWeeklyAsync(weekStart);
            }
        }
    }
}

