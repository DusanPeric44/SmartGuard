using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    // Reference/lookup tables are readable by any authenticated user (base [Authorize] from
    // BaseGetController), but only Admin may create/edit/delete them.
    public class DeviceStatusesController : BaseCRUDController<DeviceStatus, BaseSearchObject, DeviceStatusUpsertRequest, DeviceStatusUpsertRequest>
    {
        public DeviceStatusesController(IDeviceStatusesService service) : base(service) { }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public override Task<DeviceStatus> Insert([FromBody] DeviceStatusUpsertRequest insert) => base.Insert(insert);

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public override Task<DeviceStatus> Update(int id, [FromBody] DeviceStatusUpsertRequest update) => base.Update(id, update);

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public override Task<bool> Delete(int id) => base.Delete(id);
    }

    public class RecordingTypesController : BaseCRUDController<RecordingType, BaseSearchObject, RecordingTypeUpsertRequest, RecordingTypeUpsertRequest>
    {
        public RecordingTypesController(IRecordingTypesService service) : base(service) { }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public override Task<RecordingType> Insert([FromBody] RecordingTypeUpsertRequest insert) => base.Insert(insert);

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public override Task<RecordingType> Update(int id, [FromBody] RecordingTypeUpsertRequest update) => base.Update(id, update);

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public override Task<bool> Delete(int id) => base.Delete(id);
    }

    public class RecordingStatusesController : BaseCRUDController<RecordingStatus, BaseSearchObject, RecordingStatusUpsertRequest, RecordingStatusUpsertRequest>
    {
        public RecordingStatusesController(IRecordingStatusesService service) : base(service) { }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public override Task<RecordingStatus> Insert([FromBody] RecordingStatusUpsertRequest insert) => base.Insert(insert);

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public override Task<RecordingStatus> Update(int id, [FromBody] RecordingStatusUpsertRequest update) => base.Update(id, update);

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public override Task<bool> Delete(int id) => base.Delete(id);
    }

    public class AlertTypesController : BaseCRUDController<AlertType, BaseSearchObject, AlertTypeUpsertRequest, AlertTypeUpsertRequest>
    {
        public AlertTypesController(IAlertTypesService service) : base(service) { }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public override Task<AlertType> Insert([FromBody] AlertTypeUpsertRequest insert) => base.Insert(insert);

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public override Task<AlertType> Update(int id, [FromBody] AlertTypeUpsertRequest update) => base.Update(id, update);

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public override Task<bool> Delete(int id) => base.Delete(id);
    }

    public class AlertStatusesController : BaseCRUDController<AlertStatus, BaseSearchObject, AlertStatusUpsertRequest, AlertStatusUpsertRequest>
    {
        public AlertStatusesController(IAlertStatusesService service) : base(service) { }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public override Task<AlertStatus> Insert([FromBody] AlertStatusUpsertRequest insert) => base.Insert(insert);

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public override Task<AlertStatus> Update(int id, [FromBody] AlertStatusUpsertRequest update) => base.Update(id, update);

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public override Task<bool> Delete(int id) => base.Delete(id);
    }

    public class ReportTypesController : BaseCRUDController<ReportType, BaseSearchObject, ReportTypeUpsertRequest, ReportTypeUpsertRequest>
    {
        public ReportTypesController(IReportTypesService service) : base(service) { }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public override Task<ReportType> Insert([FromBody] ReportTypeUpsertRequest insert) => base.Insert(insert);

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public override Task<ReportType> Update(int id, [FromBody] ReportTypeUpsertRequest update) => base.Update(id, update);

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public override Task<bool> Delete(int id) => base.Delete(id);
    }

    public class ReportStatusesController : BaseCRUDController<ReportStatus, BaseSearchObject, ReportStatusUpsertRequest, ReportStatusUpsertRequest>
    {
        public ReportStatusesController(IReportStatusesService service) : base(service) { }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public override Task<ReportStatus> Insert([FromBody] ReportStatusUpsertRequest insert) => base.Insert(insert);

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public override Task<ReportStatus> Update(int id, [FromBody] ReportStatusUpsertRequest update) => base.Update(id, update);

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public override Task<bool> Delete(int id) => base.Delete(id);
    }
}
