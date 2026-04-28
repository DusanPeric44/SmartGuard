using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class NotificationsService : BaseCRUDService<Model.DTOs.Notification, Database.Notification, NotificationSearchObject, NotificationInsertRequest, NotificationUpdateRequest>, INotificationsService
    {
        public NotificationsService(SmartGuardContext context) : base(context)
        {
        }
    }
}
