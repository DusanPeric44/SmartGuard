using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class UserNotificationPreferencesController : BaseCRUDController<UserNotificationPreference, UserNotificationPreferenceSearchObject, UserNotificationPreferenceInsertRequest, UserNotificationPreferenceUpdateRequest>
    {
        public UserNotificationPreferencesController(IUserNotificationPreferencesService service) : base(service)
        {
        }
    }
}
