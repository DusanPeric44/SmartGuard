using System;
using System.Linq;
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

        protected override IQueryable<Database.Recording> AddFilter(IQueryable<Database.Recording> query, RecordingSearchObject search = null)
        {
            if (search == null)
            {
                return query;
            }

            if (!string.IsNullOrWhiteSpace(search.Term))
            {
                var term = search.Term.Trim();
                query = query.Where(x => x.FilePath != null && x.FilePath.Contains(term));
            }

            if (search.DeviceId > 0)
            {
                query = query.Where(x => x.DeviceId == search.DeviceId);
            }

            if (search.RecordingTypeId > 0)
            {
                query = query.Where(x => x.TypeId == search.RecordingTypeId);
            }

            if (search.RecordingStatusId > 0)
            {
                query = query.Where(x => x.StatusId == search.RecordingStatusId);
            }

            if (search.Start != default(DateTime))
            {
                query = query.Where(x => x.Timestamp >= search.Start);
            }

            if (search.End != default(DateTime))
            {
                query = query.Where(x => x.Timestamp <= search.End);
            }

            return query;
        }
    }
}
