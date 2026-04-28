using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class RecordingsService : BaseCRUDService<Model.DTOs.Recording, Database.Recording, RecordingSearchObject, RecordingInsertRequest, RecordingUpdateRequest>, IRecordingsService
    {
        public RecordingsService(SmartGuardContext context) : base(context)
        {
        }
    }
}
