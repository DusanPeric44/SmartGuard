using System.Threading.Tasks;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.Model.Interfaces
{
    public interface IDevicesService : IBaseCRUDService<Device, DeviceSearchObject, DeviceInsertRequest, DeviceUpdateRequest>
    {
        Task<Device> RegisterDeviceAsync(DeviceRegistrationRequest request);
        Task<DeviceDetails> GetDetailsAsync(int id);
        Task<bool> ValidateAsync(int deviceId, string deviceToken);
    }
}
