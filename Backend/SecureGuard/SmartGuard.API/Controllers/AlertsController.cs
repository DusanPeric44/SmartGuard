using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class AlertsController : BaseCRUDController<Alert, AlertSearchObject, AlertInsertRequest, AlertUpdateRequest>
    {
        private readonly IAlertsService _alertsService;

        public AlertsController(IAlertsService service) : base(service)
        {
            _alertsService = service;
        }

        [HttpPost("{id}/dismiss")]
        [Authorize(Roles = "Admin,HomeOwner")]
        public virtual Task<Alert> Dismiss(int id, [FromBody] AlertDismissRequest request)
        {
            return _alertsService.DismissAsync(id, request.DismissalReason);
        }

        [HttpPost("{id}/confirm")]
        [Authorize(Roles = "Admin,HomeOwner")]
        public virtual Task<Alert> Confirm(int id)
        {
            return _alertsService.ConfirmAsync(id);
        }

        [HttpPost("{id}/resolve")]
        [Authorize(Roles = "Admin")]
        public virtual Task<Alert> Resolve(int id)
        {
            return _alertsService.ResolveAsync(id);
        }
    }
}
