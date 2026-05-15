using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class UserDeviceAccessController : BaseCRUDController<UserDeviceAccess, UserDeviceAccessSearchObject, UserDeviceAccessInsertRequest, UserDeviceAccessUpdateRequest>
    {
        private readonly IUserDeviceAccessService _userDeviceAccessService;

        public UserDeviceAccessController(IUserDeviceAccessService service) : base(service)
        {
            _userDeviceAccessService = service;
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public override Task<UserDeviceAccess> Insert([FromBody] UserDeviceAccessInsertRequest insert)
        {
            return _userDeviceAccessService.InsertAsync(insert);
        }
    }
}
