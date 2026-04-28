using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class RecordingsController : BaseCRUDController<Recording, RecordingSearchObject, RecordingInsertRequest, RecordingUpdateRequest>
    {
        public RecordingsController(IRecordingsService service) : base(service)
        {
        }

        [HttpPost("{id}/request-clip")]
        public virtual Task<Recording> RequestClip(int id)
        {
            throw new NotImplementedException();
        }
    }
}
