using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class ScheduledRecordingsController : BaseCRUDController<ScheduledRecording, ScheduledRecordingSearchObject, ScheduledRecordingInsertRequest, ScheduledRecordingUpdateRequest>
    {
        public ScheduledRecordingsController(IScheduledRecordingsService service) : base(service)
        {
        }
    }
}
