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
        public DevicesController(IDevicesService service) : base(service)
        {
        }

        [HttpPatch("{id}/status")]
        public virtual Task<Device> UpdateStatus(int id, [FromBody] string status)
        {
            throw new NotImplementedException();
        }
    }
}
