using SmartGuard.Model.DTOs;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.Model.Interfaces
{
    public interface IAuditLogsService : IBaseGetService<AuditLog, AuditLogSearchObject>
    {
    }
}
