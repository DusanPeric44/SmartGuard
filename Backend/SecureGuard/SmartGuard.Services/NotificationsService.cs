using Microsoft.EntityFrameworkCore;
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

        public async Task<bool> MarkAsReadAsync(int id)
        {
            var entity = await _context.Notifications.FindAsync(id);
            if (entity == null) return false;

            entity.IsRead = true;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<int> MarkAllAsReadAsync(string userId)
        {
            var notifications = await _context.Notifications
                .Where(x => x.UserId == userId && !x.IsRead)
                .ToListAsync();

            foreach (var n in notifications)
            {
                n.IsRead = true;
            }

            await _context.SaveChangesAsync();
            return notifications.Count;
        }
    }
}
