using Mapster;
using Microsoft.EntityFrameworkCore;
using SmartGuard.Model;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;
using SmartGuard.Services.Audit;
using Microsoft.Extensions.Logging;

namespace SmartGuard.Services
{
    public class AlertsService : BaseCRUDService<Model.DTOs.Alert, Database.Alert, AlertSearchObject, AlertInsertRequest, AlertUpdateRequest>, IAlertsService
    {
        private readonly ILogger<AlertsService> _logger;
        private readonly IUserContext _userContext;
        private readonly IDeviceAccessService _deviceAccessService;

        public AlertsService(SmartGuardContext context, ILogger<AlertsService> logger, IUserContext userContext, IDeviceAccessService deviceAccessService) : base(context)
        {
            _logger = logger;
            _userContext = userContext;
            _deviceAccessService = deviceAccessService;
        }

        private async Task EnsureCanAccessAlertDeviceAsync(Database.Alert alert)
        {
            if (_userContext.IsAdmin) return;
            if (!alert.DeviceId.HasValue ||
                !await _deviceAccessService.CanAccessDeviceAsync(_userContext.UserId, alert.DeviceId.Value, DeviceAccessPermission.View, _userContext.IsAdmin))
            {
                throw new UnauthorizedAccessException("You don't have access to this alert's device");
            }
        }

        public async Task<Model.DTOs.Alert> ConfirmAsync(int id)
        {
            return await UpdateStatusAsync(id, 2, dismissalReason: null);
        }

        public async Task<Model.DTOs.Alert> DismissAsync(int id, string dismissalReason)
        {
            if (string.IsNullOrWhiteSpace(dismissalReason))
            {
                throw new UserException("Dismissal reason is mandatory for dismissing an alert");
            }

            return await UpdateStatusAsync(id, 3, dismissalReason);
        }

        public async Task<Model.DTOs.Alert> ResolveAsync(int id)
        {
            return await UpdateStatusAsync(id, 4, dismissalReason: null);
        }

        protected override IQueryable<Database.Alert> AddFilter(IQueryable<Database.Alert> query, AlertSearchObject search = null)
        {
            query = base.AddFilter(query, search);

            if (!_userContext.IsAdmin)
            {
                var userId = _userContext.UserId;
                query = query.Where(x => x.DeviceId.HasValue &&
                    _context.UserDeviceAccesses.Any(a => a.UserId == userId && a.DeviceId == x.DeviceId));
            }

            if (!string.IsNullOrWhiteSpace(search?.StatusName))
            {
                var statusName = search.StatusName.Trim().ToLower();
                query = query.Where(x => x.AlertStatus.Name.ToLower() == statusName);
            }

            return query;
        }

        protected override IQueryable<Database.Alert> AddInclude(IQueryable<Database.Alert> query, AlertSearchObject search = null)
        {
            return query
                .Include(x => x.AlertType)
                .Include(x => x.AlertStatus)
                .Include(x => x.Device)
                .Include(x => x.LinkedEvent);
        }

        public override async Task<Model.DTOs.Alert> UpdateAsync(int id, AlertUpdateRequest update)
        {
            var entity = await _context.Alerts.FindAsync(id);
            if (entity == null) throw new UserException("Alert not found");

            await EnsureCanAccessAlertDeviceAsync(entity);

            if (update.StatusId.HasValue)
            {
                ValidateStateTransition(entity.StatusId, update.StatusId.Value);
                update.ConfirmedByUserId = _userContext.UserId;

                if (update.StatusId.Value == 3) // Dismissed
                {
                    if (string.IsNullOrWhiteSpace(update.DismissalReason))
                        throw new UserException("Dismissal reason is mandatory for dismissing an alert");

                    _logger.LogAuditSuccess("AlertDismissed", $"Alert:{id}", update.DismissalReason);
                }
                else if (update.StatusId.Value == 2)
                {
                    _logger.LogAuditSuccess("AlertConfirmed", $"Alert:{id}", string.Empty);
                }
                else if (update.StatusId.Value == 4)
                {
                    _logger.LogAuditSuccess("AlertResolved", $"Alert:{id}", string.Empty);
                }
            }

            return await base.UpdateAsync(id, update);
        }

        private async Task<Model.DTOs.Alert> UpdateStatusAsync(int id, int statusId, string? dismissalReason)
        {
            var entity = await _context.Alerts.SingleOrDefaultAsync(x => x.Id == id);
            if (entity == null) throw new UserException("Alert not found");

            await EnsureCanAccessAlertDeviceAsync(entity);

            ValidateStateTransition(entity.StatusId, statusId);

            var userId = _userContext.UserId;
            if (string.IsNullOrWhiteSpace(userId))
            {
                throw new UnauthorizedAccessException();
            }

            entity.StatusId = statusId;
            entity.ConfirmedByUserId = userId;

            if (statusId == 3)
            {
                entity.DismissalReason = dismissalReason;
                _logger.LogAuditSuccess("AlertDismissed", $"Alert:{id}", dismissalReason ?? string.Empty);
            }
            else if (statusId == 2)
            {
                entity.DismissalReason = null;
                _logger.LogAuditSuccess("AlertConfirmed", $"Alert:{id}", string.Empty);
            }
            else if (statusId == 4)
            {
                entity.DismissalReason = null;
                _logger.LogAuditSuccess("AlertResolved", $"Alert:{id}", string.Empty);
            }

            await _context.SaveChangesAsync();

            return entity.Adapt<Model.DTOs.Alert>();
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
