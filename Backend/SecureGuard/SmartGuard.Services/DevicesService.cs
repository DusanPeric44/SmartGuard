using Microsoft.EntityFrameworkCore;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class DevicesService : BaseCRUDService<Model.DTOs.Device, Database.Device, DeviceSearchObject, DeviceInsertRequest, DeviceUpdateRequest>, IDevicesService
    {
        public DevicesService(SmartGuardContext context) : base(context)
        {
        }

        public async Task<bool> UpdateStatusAsync(int id, int statusId)
        {
            var entity = await _context.Devices.FindAsync(id);
            if (entity == null) return false;

            // 1 - Online, 2 - Offline, 3 - Maintenance
            if (statusId < 1 || statusId > 3) throw new ArgumentException("Invalid status ID");

            entity.StatusId = statusId;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> HasAccessAsync(string userId, int deviceId, string permission)
        {
            var access = await _context.UserDeviceAccesses
                .FirstOrDefaultAsync(x => x.UserId == userId && x.DeviceId == deviceId);

            if (access == null) return false;

            return permission.ToLower() switch
            {
                "stream" => access.CanStream,
                "download" => access.CanDownload,
                _ => false
            };
        }
    }
}
