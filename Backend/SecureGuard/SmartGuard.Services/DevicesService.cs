using Microsoft.EntityFrameworkCore;
using SmartGuard.Model;
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

        public async Task<Model.DTOs.Device> RegisterDeviceAsync(DeviceRegistrationRequest request)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.RegistrationKey == request.RegistrationKey)
                ?? throw new UserException("Invalid registration key");

            var device = await _context.Devices
                .FirstOrDefaultAsync(d => d.MacAddress == request.MacAddress);

            if (device == null)
            {
                device = new Database.Device
                {
                    MacAddress = request.MacAddress,
                    Name = $"ESP32-Cam-{request.MacAddress.Replace(":", "").Substring(Math.Max(0, request.MacAddress.Length - 4))}",
                    Location = "Default",
                    StatusId = 1, // Online
                    ApiKey = Guid.NewGuid().ToString() // This will be the Device Token
                };
                _context.Devices.Add(device);
            }
            else
            {
                // If device exists, update its token just in case or keep it
                device.ApiKey = Guid.NewGuid().ToString();
            }

            await _context.SaveChangesAsync();

            // Check if user already has access
            var access = await _context.UserDeviceAccesses
                .FirstOrDefaultAsync(a => a.UserId == user.Id && a.DeviceId == device.Id);

            if (access == null)
            {
                access = new Database.UserDeviceAccess
                {
                    UserId = user.Id,
                    DeviceId = device.Id,
                    CanStream = true,
                    CanDownload = true
                };
                _context.UserDeviceAccesses.Add(access);
                await _context.SaveChangesAsync();
            }

            // Map to DTO
            return new Model.DTOs.Device
            {
                Id = device.Id,
                Name = device.Name,
                Location = device.Location,
                IPAddress = device.IPAddress,
                ApiKey = device.ApiKey
            };
        }
    }
}
