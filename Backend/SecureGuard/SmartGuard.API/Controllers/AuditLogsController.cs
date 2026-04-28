using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class AuditLogsController : BaseGetController<AuditLog, AuditLogSearchObject>
    {
        public AuditLogsController(IAuditLogsService service) : base(service)
        {
        }
    }
}
