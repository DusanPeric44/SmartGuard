using SmartGuard.Services.Audit;
using SmartGuard.Services.Database;

namespace SmartGuard.API.Services
{
    public class AuditLoggerBackgroundWriter : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly AuditLogChannel _channel;

        public AuditLoggerBackgroundWriter(IServiceScopeFactory scopeFactory, AuditLogChannel channel)
        {
            _scopeFactory = scopeFactory;
            _channel = channel;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            await foreach (var evt in _channel.Channel.Reader.ReadAllAsync(stoppingToken))
            {
                await using var scope = _scopeFactory.CreateAsyncScope();
                var db = scope.ServiceProvider.GetRequiredService<SmartGuardContext>();

                db.AuditLogs.Add(new AuditLog
                {
                    UserId = evt.UserId,
                    Action = evt.Action,
                    Resource = evt.Resource,
                    Status = evt.Status,
                    Timestamp = evt.TimestampUtc,
                    Details = string.IsNullOrWhiteSpace(evt.TraceId) ? evt.Details : $"{evt.Details}{Environment.NewLine}TraceId={evt.TraceId}"
                });

                await db.SaveChangesAsync(stoppingToken);
                db.ChangeTracker.Clear();
            }
        }
    }
}
