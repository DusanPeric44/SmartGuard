using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class UserNotificationPreferencesService : BaseCRUDService<Model.DTOs.UserNotificationPreference, Database.UserNotificationPreference, UserNotificationPreferenceSearchObject, UserNotificationPreferenceInsertRequest, UserNotificationPreferenceUpdateRequest>, IUserNotificationPreferencesService
    {
        public UserNotificationPreferencesService(SmartGuardContext context) : base(context)
        {
        }
    }
}
