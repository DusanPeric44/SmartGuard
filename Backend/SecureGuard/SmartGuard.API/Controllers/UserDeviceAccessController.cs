using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class UserDeviceAccessController : BaseCRUDController<UserDeviceAccess, UserDeviceAccessSearchObject, UserDeviceAccessInsertRequest, UserDeviceAccessUpdateRequest>
    {
        public UserDeviceAccessController(IUserDeviceAccessService service) : base(service)
        {
        }
    }
}
