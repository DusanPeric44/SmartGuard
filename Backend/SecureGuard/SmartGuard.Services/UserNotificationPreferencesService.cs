using Mapster;
using Microsoft.EntityFrameworkCore;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class UserNotificationPreferencesService : BaseCRUDService<Model.DTOs.UserNotificationPreference, Database.UserNotificationPreference, UserNotificationPreferenceSearchObject, UserNotificationPreferenceInsertRequest, UserNotificationPreferenceUpdateRequest>, IUserNotificationPreferencesService
    {
        private readonly IUserContext _userContext;

        public UserNotificationPreferencesService(SmartGuardContext context, IUserContext userContext) : base(context)
        {
            _userContext = userContext;
        }

        protected override IQueryable<Database.UserNotificationPreference> AddFilter(IQueryable<Database.UserNotificationPreference> query, UserNotificationPreferenceSearchObject search = null)
        {
            var userEmail = _userContext.Email;
            if (!string.IsNullOrWhiteSpace(userEmail))
            {
                query = query.Where(x => x.User.Email == userEmail);
            }

            return query;
        }

        protected override IQueryable<Database.UserNotificationPreference> AddInclude(IQueryable<Database.UserNotificationPreference> query, UserNotificationPreferenceSearchObject search = null)
        {
            return query.Include(x => x.Person);
        }

        public override async Task<Model.DTOs.UserNotificationPreference> GetByIdAsync(int id)
        {
            var userEmail = _userContext.Email;
            if (string.IsNullOrWhiteSpace(userEmail))
            {
                return null;
            }

            var entity = await _context.UserNotificationPreferences
                .Include(x => x.Person)
                .Include(x => x.User)
                .FirstOrDefaultAsync(x => x.Id == id && x.User.Email == userEmail);

            return entity?.Adapt<Model.DTOs.UserNotificationPreference>();
        }

        public async Task<Model.DTOs.UserNotificationPreference> UpdateEnabledAsync(int personId, bool enabled)
        {
            var userEmail = _userContext.Email;
            if (string.IsNullOrWhiteSpace(userEmail))
            {
                return null;
            }

            var entity = await _context.UserNotificationPreferences
                .Include(x => x.Person)
                .Include(x => x.User)
                .FirstOrDefaultAsync(x => x.PersonId == personId && x.User.Email == userEmail);

            if (entity == null)
            {
                return null;
            }

            entity.Enabled = enabled;
            await _context.SaveChangesAsync();
            return entity.Adapt<Model.DTOs.UserNotificationPreference>();
        }
    }
}
