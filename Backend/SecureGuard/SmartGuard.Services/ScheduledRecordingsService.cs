using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class ScheduledRecordingsService : BaseCRUDService<Model.DTOs.ScheduledRecording, Database.ScheduledRecording, ScheduledRecordingSearchObject, ScheduledRecordingInsertRequest, ScheduledRecordingUpdateRequest>, IScheduledRecordingsService
    {
        public ScheduledRecordingsService(SmartGuardContext context) : base(context)
        {
        }
    }
}
