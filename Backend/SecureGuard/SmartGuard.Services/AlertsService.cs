using SmartGuard.Model;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class AlertsService : BaseCRUDService<Model.DTOs.Alert, Database.Alert, AlertSearchObject, AlertInsertRequest, AlertUpdateRequest>, IAlertsService
    {
        private readonly IAuditLogsService _auditLogsService;

        public AlertsService(SmartGuardContext context, IAuditLogsService auditLogsService) : base(context)
        {
            _auditLogsService = auditLogsService;
        }

        public override async Task<Model.DTOs.Alert> UpdateAsync(int id, AlertUpdateRequest update)
        {
            var entity = await _context.Alerts.FindAsync(id);
            if (entity == null) throw new UserException("Alert not found");

            if (update.StatusId.HasValue)
            {
                ValidateStateTransition(entity.StatusId, update.StatusId.Value);

                if (update.StatusId.Value == 3) // Dismissed
                {
                    if (string.IsNullOrWhiteSpace(update.DismissalReason))
                        throw new UserException("Dismissal reason is mandatory for dismissing an alert");

                    entity.DismissalReason = update.DismissalReason;

                    // Log to AuditLogs
                    await _auditLogsService.InsertAsync(new AuditLogInsertRequest
                    {
                        Action = "Alert Dismissed",
                        Details = $"Alert {id} dismissed. Reason: {update.DismissalReason}",
                        Timestamp = DateTime.UtcNow,
                        UserId = update.ConfirmedByUserId ?? "System"
                    });
                }
            }

            return await base.UpdateAsync(id, update);
        }

        private void ValidateStateTransition(int currentStatusId, int newStatusId)
        {
            // 1 - Pending, 2 - Confirmed, 3 - Dismissed, 4 - Resolved
            bool isValid = currentStatusId switch
            {
                1 => newStatusId == 2 || newStatusId == 3,
                2 => newStatusId == 4,
                3 => false, // Cannot change from Dismissed
                4 => false, // Cannot change from Resolved
                _ => false
            };

            if (!isValid)
                throw new UserException($"Invalid status transition from {currentStatusId} to {newStatusId}");
        }
    }
}
