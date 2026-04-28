using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class AuditLogsService : BaseGetService<Model.DTOs.AuditLog, Database.AuditLog, AuditLogSearchObject>, IAuditLogsService
    {
        public AuditLogsService(SmartGuardContext context) : base(context)
        {
        }
    }
}
