using SmartGuard.Model.DTOs;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.Model.Interfaces
{
    public interface IUserNotificationPreferencesService : IBaseCRUDService<UserNotificationPreference, UserNotificationPreferenceSearchObject, UserNotificationPreferenceInsertRequest, UserNotificationPreferenceUpdateRequest>
    {
        Task<UserNotificationPreference> UpdateEnabledAsync(int personId, bool enabled);
    }
}
