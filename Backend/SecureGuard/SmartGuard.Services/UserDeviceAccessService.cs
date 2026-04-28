using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class UserDeviceAccessService : BaseCRUDService<Model.DTOs.UserDeviceAccess, Database.UserDeviceAccess, UserDeviceAccessSearchObject, UserDeviceAccessInsertRequest, UserDeviceAccessUpdateRequest>, IUserDeviceAccessService
    {
        public UserDeviceAccessService(SmartGuardContext context) : base(context)
        {
        }
    }
}
