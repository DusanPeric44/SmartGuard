using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

using SmartGuard.Model.Requests;

namespace SmartGuard.Services
{
    public class AuditLogsService : BaseCRUDService<Model.DTOs.AuditLog, Database.AuditLog, AuditLogSearchObject, AuditLogInsertRequest, object>, IAuditLogsService
    {
        public AuditLogsService(SmartGuardContext context) : base(context)
        {
        }
    }
}
