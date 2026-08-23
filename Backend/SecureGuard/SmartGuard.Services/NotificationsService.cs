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
        private readonly IUserContext _userContext;
        public NotificationsService(SmartGuardContext context, IUserContext userContext) : base(context)
        {
            _userContext = userContext;
        }

        public override async Task<Model.DTOs.Notification> GetByIdAsync(int id)
        {
            var notification = await base.GetByIdAsync(id);
            if (notification == null || notification.UserId != _userContext.UserId)
            {
                return null;
            }

            return notification;
        }

        public async Task<bool> MarkAsReadAsync(int id)
        {
            var entity = await _context.Notifications.FindAsync(id);
            if (entity == null || entity.UserId != _userContext.UserId) return false;

            entity.IsRead = true;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<int> MarkAllAsReadAsync()
        {
            var userId = _userContext.UserId;
            if (string.IsNullOrWhiteSpace(userId))
            {
                return 0;
            }

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

        protected override IQueryable<Database.Notification> AddFilter(IQueryable<Database.Notification> query, NotificationSearchObject search = null)
        {
            query = base.AddFilter(query, search);

            query = query.Where(x => x.UserId == _userContext.UserId)
                         .Where(x => search.IsRead == null || x.IsRead == search.IsRead);

            return query;
        }
    }
}
