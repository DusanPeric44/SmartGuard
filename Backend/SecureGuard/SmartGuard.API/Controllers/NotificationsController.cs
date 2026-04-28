using System;
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
        public NotificationsController(INotificationsService service) : base(service)
        {
        }

        [HttpPatch("{id}/read")]
        public virtual Task<Notification> MarkAsRead(int id)
        {
            throw new NotImplementedException();
        }
    }
}
