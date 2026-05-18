using System;
using System.Collections.Generic;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using SmartGuard.Services.Audit;

namespace SmartGuard.API.Services
{
    public class AuditLoggerProvider : ILoggerProvider
    {
        private readonly AuditLogChannel _channel;
        private readonly IHttpContextAccessor _httpContextAccessor;

        public AuditLoggerProvider(AuditLogChannel channel, IHttpContextAccessor httpContextAccessor)
        {
            _channel = channel;
            _httpContextAccessor = httpContextAccessor;
        }

        public ILogger CreateLogger(string categoryName) => new AuditLogger(_channel, _httpContextAccessor);

        public void Dispose()
        {
        }

        private sealed class AuditLogger : ILogger
        {
            private readonly AuditLogChannel _channel;
            private readonly IHttpContextAccessor _httpContextAccessor;

            public AuditLogger(AuditLogChannel channel, IHttpContextAccessor httpContextAccessor)
            {
                _channel = channel;
                _httpContextAccessor = httpContextAccessor;
            }

            public IDisposable BeginScope<TState>(TState state) where TState : notnull => NullScope.Instance;

            public bool IsEnabled(LogLevel logLevel) => true;

            public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter)
            {
                if (eventId.Id != LoggerAuditExtensions.AuditEventId.Id)
                {
                    return;
                }

                if (state is not IEnumerable<KeyValuePair<string, object>> kvs)
                {
                    return;
                }

                string? explicitUserId = null;
                string? action = null;
                string? resource = null;
                string? status = null;
                string? details = null;

                foreach (var kv in kvs)
                {
                    if (kv.Key == "UserId") explicitUserId = kv.Value?.ToString();
                    else if (kv.Key == "Action") action = kv.Value?.ToString();
                    else if (kv.Key == "Resource") resource = kv.Value?.ToString();
                    else if (kv.Key == "Status") status = kv.Value?.ToString();
                    else if (kv.Key == "Details") details = kv.Value?.ToString();
                }

                if (string.IsNullOrWhiteSpace(action) ||
                    string.IsNullOrWhiteSpace(resource) ||
                    string.IsNullOrWhiteSpace(status) ||
                    string.IsNullOrWhiteSpace(details))
                {
                    return;
                }

                var httpContext = _httpContextAccessor.HttpContext;
                var userId = !string.IsNullOrWhiteSpace(explicitUserId)
                    ? explicitUserId
                    : httpContext?.User?.FindFirst("UserId")?.Value;

                var traceId = httpContext?.TraceIdentifier ?? string.Empty;

                _channel.Channel.Writer.TryWrite(new AuditEvent(
                    TimestampUtc: DateTime.UtcNow,
                    UserId: userId,
                    Action: action!,
                    Resource: resource!,
                    Details: details!,
                    Status: status!,
                    TraceId: traceId));
            }
        }

        private sealed class NullScope : IDisposable
        {
            public static NullScope Instance { get; } = new();
            public void Dispose()
            {
            }
        }
    }
}
