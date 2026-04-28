using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class DeviceStatusesController : BaseCRUDController<DeviceStatus, BaseSearchObject, DeviceStatusUpsertRequest, DeviceStatusUpsertRequest>
    {
        public DeviceStatusesController(IDeviceStatusesService service) : base(service) { }
    }

    public class RecordingTypesController : BaseCRUDController<RecordingType, BaseSearchObject, RecordingTypeUpsertRequest, RecordingTypeUpsertRequest>
    {
        public RecordingTypesController(IRecordingTypesService service) : base(service) { }
    }

    public class RecordingStatusesController : BaseCRUDController<RecordingStatus, BaseSearchObject, RecordingStatusUpsertRequest, RecordingStatusUpsertRequest>
    {
        public RecordingStatusesController(IRecordingStatusesService service) : base(service) { }
    }

    public class AlertTypesController : BaseCRUDController<AlertType, BaseSearchObject, AlertTypeUpsertRequest, AlertTypeUpsertRequest>
    {
        public AlertTypesController(IAlertTypesService service) : base(service) { }
    }

    public class AlertStatusesController : BaseCRUDController<AlertStatus, BaseSearchObject, AlertStatusUpsertRequest, AlertStatusUpsertRequest>
    {
        public AlertStatusesController(IAlertStatusesService service) : base(service) { }
    }

    public class CitiesController : BaseCRUDController<City, BaseSearchObject, CityUpsertRequest, CityUpsertRequest>
    {
        public CitiesController(ICitiesService service) : base(service) { }
    }

    public class CountriesController : BaseCRUDController<Country, BaseSearchObject, CountryUpsertRequest, CountryUpsertRequest>
    {
        public CountriesController(ICountriesService service) : base(service) { }
    }
}
