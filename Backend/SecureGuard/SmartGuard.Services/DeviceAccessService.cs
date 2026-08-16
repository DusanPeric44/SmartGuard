using Microsoft.EntityFrameworkCore;
using SmartGuard.Model.Interfaces;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class DeviceAccessService : IDeviceAccessService
    {
        private readonly SmartGuardContext _context;

        public DeviceAccessService(SmartGuardContext context)
        {
            _context = context;
        }

        public async Task<bool> CanAccessDeviceAsync(string userId, int deviceId, DeviceAccessPermission permission, bool isAdmin = false)
        {
            if (isAdmin) return true;
            if (string.IsNullOrEmpty(userId)) return false;

            var access = await _context.UserDeviceAccesses
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.UserId == userId && x.DeviceId == deviceId);

            if (access == null) return false;

            return permission switch
            {
                DeviceAccessPermission.View => true,
                DeviceAccessPermission.Stream => access.CanStream,
                DeviceAccessPermission.Download => access.CanDownload,
                _ => false
            };
        }

        public async Task<List<int>> GetAccessibleDeviceIdsAsync(string userId)
        {
            if (string.IsNullOrEmpty(userId)) return new List<int>();

            return await _context.UserDeviceAccesses
                .AsNoTracking()
                .Where(x => x.UserId == userId && x.DeviceId.HasValue)
                .Select(x => x.DeviceId!.Value)
                .Distinct()
                .ToListAsync();
        }
    }
}
