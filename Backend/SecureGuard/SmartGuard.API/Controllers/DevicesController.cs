using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class DevicesController : BaseCRUDController<Device, DeviceSearchObject, DeviceInsertRequest, DeviceUpdateRequest>
    {
        private readonly IDevicesService _devicesService;

        public DevicesController(IDevicesService service) : base(service)
        {
            _devicesService = service;
        }

        [HttpPatch("{id}/status")]
        public virtual Task<Device> UpdateStatus(int id, [FromBody] string status)
        {
            throw new NotImplementedException();
        }

        [HttpPost("register")]
        [Microsoft.AspNetCore.Authorization.AllowAnonymous]
        public async Task<ActionResult<Device>> Register([FromBody] DeviceRegistrationRequest request)
        {
            try
            {
                var device = await _devicesService.RegisterDeviceAsync(request);
                return Ok(device);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}
