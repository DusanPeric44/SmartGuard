using SmartGuard.Model.DTOs;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.Model.Interfaces
{
    public interface IDeviceStatusesService : IBaseCRUDService<DeviceStatus, BaseSearchObject, DeviceStatusUpsertRequest, DeviceStatusUpsertRequest> { }
    public interface IRecordingTypesService : IBaseCRUDService<RecordingType, BaseSearchObject, RecordingTypeUpsertRequest, RecordingTypeUpsertRequest> { }
    public interface IRecordingStatusesService : IBaseCRUDService<RecordingStatus, BaseSearchObject, RecordingStatusUpsertRequest, RecordingStatusUpsertRequest> { }
    public interface IAlertTypesService : IBaseCRUDService<AlertType, BaseSearchObject, AlertTypeUpsertRequest, AlertTypeUpsertRequest> { }
    public interface IAlertStatusesService : IBaseCRUDService<AlertStatus, BaseSearchObject, AlertStatusUpsertRequest, AlertStatusUpsertRequest> { }
    public interface ICitiesService : IBaseCRUDService<City, BaseSearchObject, CityUpsertRequest, CityUpsertRequest> { }
    public interface ICountriesService : IBaseCRUDService<Country, BaseSearchObject, CountryUpsertRequest, CountryUpsertRequest> { }
}
