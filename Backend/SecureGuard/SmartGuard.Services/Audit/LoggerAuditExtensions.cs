using Microsoft.Extensions.Logging;

namespace SmartGuard.Services.Audit
{
    public static class LoggerAuditExtensions
    {
        public static readonly EventId AuditEventId = new(10000, "AUDIT");

        public static void LogAuditSuccess(this ILogger logger, string? userId, string action, string resource, string details)
        {
            logger.LogInformation(AuditEventId, "{UserId} {Action} {Resource} {Status} {Details}", userId, action, resource, "Success", details);
        }

        public static void LogAuditSuccess(this ILogger logger, string action, string resource, string details)
        {
            logger.LogInformation(AuditEventId, "{Action} {Resource} {Status} {Details}", action, resource, "Success", details);
        }

        public static void LogAuditFailed(this ILogger logger, string? userId, string action, string resource, string details, Exception? ex = null)
        {
            var d = ex == null ? details : $"{details}{Environment.NewLine}{ex}";
            logger.LogError(AuditEventId, ex, "{UserId} {Action} {Resource} {Status} {Details}", userId, action, resource, "Failed", d);
        }

        public static void LogAuditFailed(this ILogger logger, string action, string resource, string details, Exception? ex = null)
        {
            var d = ex == null ? details : $"{details}{Environment.NewLine}{ex}";
            logger.LogError(AuditEventId, ex, "{Action} {Resource} {Status} {Details}", action, resource, "Failed", d);
        }
    }
}
