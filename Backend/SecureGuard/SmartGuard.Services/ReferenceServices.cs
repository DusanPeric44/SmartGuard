using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class DeviceStatusesService : BaseCRUDService<Model.DTOs.DeviceStatus, Database.DeviceStatus, BaseSearchObject, DeviceStatusUpsertRequest, DeviceStatusUpsertRequest>, IDeviceStatusesService
    {
        public DeviceStatusesService(SmartGuardContext context) : base(context) { }
    }

    public class RecordingTypesService : BaseCRUDService<Model.DTOs.RecordingType, Database.RecordingType, BaseSearchObject, RecordingTypeUpsertRequest, RecordingTypeUpsertRequest>, IRecordingTypesService
    {
        public RecordingTypesService(SmartGuardContext context) : base(context) { }
    }

    public class RecordingStatusesService : BaseCRUDService<Model.DTOs.RecordingStatus, Database.RecordingStatus, BaseSearchObject, RecordingStatusUpsertRequest, RecordingStatusUpsertRequest>, IRecordingStatusesService
    {
        public RecordingStatusesService(SmartGuardContext context) : base(context) { }
    }

    public class AlertTypesService : BaseCRUDService<Model.DTOs.AlertType, Database.AlertType, BaseSearchObject, AlertTypeUpsertRequest, AlertTypeUpsertRequest>, IAlertTypesService
    {
        public AlertTypesService(SmartGuardContext context) : base(context) { }
    }

    public class AlertStatusesService : BaseCRUDService<Model.DTOs.AlertStatus, Database.AlertStatus, BaseSearchObject, AlertStatusUpsertRequest, AlertStatusUpsertRequest>, IAlertStatusesService
    {
        public AlertStatusesService(SmartGuardContext context) : base(context) { }
    }
}
