using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model;
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

        [HttpGet("my")]
        public async Task<PagedResult<Device>> GetMyDevices([FromQuery] DeviceSearchObject search = null)
        {
            return await _devicesService.GetAsync(search);
        }

        [HttpGet("details/{id}")]
        public new async Task<ActionResult<DeviceDetails>> GetById(int id)
        {
            var result = await _devicesService.GetDetailsAsync(id);
            if (result == null) return NotFound();
            return Ok(result);
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
