using Microsoft.EntityFrameworkCore;
using SmartGuard.Model;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;
using Mapster;
using SmartGuard.Services.Audit;
using Microsoft.Extensions.Logging;

namespace SmartGuard.Services
{
    public class DevicesService : BaseCRUDService<Model.DTOs.Device, Database.Device, DeviceSearchObject, DeviceInsertRequest, DeviceUpdateRequest>, IDevicesService
    {
        private readonly IUserContext _userContext;
        private readonly ILogger<DevicesService> _logger;

        public DevicesService(SmartGuardContext context, IUserContext userContext, ILogger<DevicesService> logger) : base(context)
        {
            _userContext = userContext;
            _logger = logger;
        }

        protected override IQueryable<Database.Device> AddFilter(IQueryable<Database.Device> query, DeviceSearchObject search = null)
        {
            query = base.AddFilter(query, search);

            var userEmail = _userContext.Email;
            if (!string.IsNullOrEmpty(userEmail))
            {
                query = query.Where(d => d.UserDeviceAccesses.Any(a => a.User.Email == userEmail));
            }

            if (!string.IsNullOrEmpty(search?.Name))
            {
                query = query.Where(d => d.Name.Contains(search.Name));
            }

            if (!string.IsNullOrEmpty(search?.Location))
            {
                query = query.Where(d => d.Location.Contains(search.Location));
            }

            if (search?.StatusId.HasValue == true)
            {
                query = query.Where(d => d.StatusId == search.StatusId);
            }

            return query;
        }

        public override async Task<Model.DTOs.Device> InsertAsync(DeviceInsertRequest insert)
        {
            try
            {
                var created = await base.InsertAsync(insert);
                _logger.LogAuditSuccess("DeviceCreated", $"Device:{created.Id}", $"Name={insert.Name}; Location={insert.Location}; StatusId={insert.StatusId}; SDCapacity={insert.SDCapacity}; FreeSpace={insert.FreeSpace}");
                return created;
            }
            catch (Exception ex)
            {
                _logger.LogAuditFailed("DeviceCreated", "Device", $"Name={insert.Name}; Location={insert.Location}; StatusId={insert.StatusId}; SDCapacity={insert.SDCapacity}; FreeSpace={insert.FreeSpace}", ex);
                throw;
            }
        }

        public override async Task<Model.DTOs.Device> UpdateAsync(int id, DeviceUpdateRequest update)
        {
            try
            {
                var updated = await base.UpdateAsync(id, update);
                if (updated != null)
                {
                    _logger.LogAuditSuccess("DeviceUpdated", $"Device:{id}", $"Name={update.Name}; Location={update.Location}; StatusId={update.StatusId}; SDCapacity={update.SDCapacity}; FreeSpace={update.FreeSpace}");
                }
                return updated;
            }
            catch (Exception ex)
            {
                _logger.LogAuditFailed("DeviceUpdated", $"Device:{id}", $"Name={update.Name}; Location={update.Location}; StatusId={update.StatusId}; SDCapacity={update.SDCapacity}; FreeSpace={update.FreeSpace}", ex);
                throw;
            }
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            try
            {
                var deleted = await base.DeleteAsync(id);
                if (deleted)
                {
                    _logger.LogAuditSuccess("DeviceDeleted", $"Device:{id}", $"DeviceId={id}");
                }
                return deleted;
            }
            catch (Exception ex)
            {
                _logger.LogAuditFailed("DeviceDeleted", $"Device:{id}", $"DeviceId={id}", ex);
                throw;
            }
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
                    Name = $"ESP32-Cam-{request.MacAddress}",
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
            _logger.LogAuditSuccess("DeviceRegistered", $"Device:{device.Id}", $"MacAddress={request.MacAddress}");
            return new Model.DTOs.Device
            {
                Id = device.Id,
                Name = device.Name,
                Location = device.Location,
                ApiKey = device.ApiKey
            };
        }

        public async Task<DeviceDetails> GetDetailsAsync(int id)
        {
            var entity = await _context.Devices
                .Include(d => d.DeviceStatus)
                .Include(d => d.UserDeviceAccesses)
                    .ThenInclude(a => a.User)
                .FirstOrDefaultAsync(d => d.Id == id);

            if (entity == null) return null;

            var details = new DeviceDetails
            {
                Device = entity.Adapt<Model.DTOs.Device>(),
                AssignedUsers = [.. entity.UserDeviceAccesses.Select(a => new DeviceUserDto
                {
                    Id = a.User.Id,
                    Username = a.User.Email ?? string.Empty
                })],
                LastSeenAt = entity.LastSeenAt != null ? DateTime.SpecifyKind(entity.LastSeenAt.Value, DateTimeKind.Utc) : DateTime.SpecifyKind(entity.CreatedAt, DateTimeKind.Utc)
            };

            return details;
        }

        public async Task<bool> ValidateAsync(int deviceId, string deviceToken)
        {
            if (deviceId <= 0 || string.IsNullOrWhiteSpace(deviceToken)) return false;

            var device = await _context.Devices
                .AsNoTracking()
                .FirstOrDefaultAsync(d => d.Id == deviceId);

            if (device == null) return false;

            return device.ApiKey == deviceToken;
        }

        protected override IQueryable<Database.Device> AddInclude(IQueryable<Database.Device> query, DeviceSearchObject search = null)
        {
            return query.Include(x => x.DeviceStatus);
        }
    }
}
