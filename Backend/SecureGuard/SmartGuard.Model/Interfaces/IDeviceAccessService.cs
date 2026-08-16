using System.Collections.Generic;
using System.Threading.Tasks;

namespace SmartGuard.Model.Interfaces
{
    public enum DeviceAccessPermission
    {
        View,
        Stream,
        Download
    }

    public interface IDeviceAccessService
    {
        Task<bool> CanAccessDeviceAsync(string userId, int deviceId, DeviceAccessPermission permission, bool isAdmin = false);

        Task<List<int>> GetAccessibleDeviceIdsAsync(string userId);
    }
}
