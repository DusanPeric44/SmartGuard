using System;

namespace SmartGuard.Services.Audit
{
    public record AuditEvent(
        DateTime TimestampUtc,
        string? UserId,
        string Action,
        string Resource,
        string Details,
        string Status,
        string TraceId);
}
