using SmartGuard.Model.DTOs;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.Model.Interfaces
{
    public interface INotificationsService : IBaseCRUDService<Notification, NotificationSearchObject, NotificationInsertRequest, NotificationUpdateRequest>
    {
        Task<bool> MarkAsReadAsync(int id);
        Task<int> MarkAllAsReadAsync();
    }
}
