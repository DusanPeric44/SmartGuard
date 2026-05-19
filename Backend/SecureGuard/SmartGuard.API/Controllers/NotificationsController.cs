using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class NotificationsController : BaseCRUDController<Notification, NotificationSearchObject, NotificationInsertRequest, NotificationUpdateRequest>
    {
        private readonly INotificationsService _notificationsService;

        public NotificationsController(INotificationsService service) : base(service)
        {
            _notificationsService = service;
        }

        [HttpPatch("{id}/read")]
        public virtual async Task<IActionResult> MarkAsRead(int id)
        {
            var ok = await _notificationsService.MarkAsReadAsync(id);
            if (!ok)
            {
                return NotFound();
            }

            return NoContent();
        }

        [HttpPost("read-all")]
        public virtual async Task<IActionResult> MarkAllAsRead()
        {
            var count = await _notificationsService.MarkAllAsReadAsync();
            return Ok(new { marked = count });
        }
    }
}
