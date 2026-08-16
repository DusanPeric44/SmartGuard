using System;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class RecordingsService : BaseCRUDService<Model.DTOs.Recording, Database.Recording, RecordingSearchObject, RecordingInsertRequest, RecordingUpdateRequest>, IRecordingsService
    {
        private readonly IUserContext _userContext;
        private readonly IDeviceAccessService _deviceAccessService;

        public RecordingsService(SmartGuardContext context, IUserContext userContext, IDeviceAccessService deviceAccessService) : base(context)
        {
            _userContext = userContext;
            _deviceAccessService = deviceAccessService;
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.Recordings.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id);
            if (entity == null) return false;

            if (!entity.DeviceId.HasValue ||
                !await _deviceAccessService.CanAccessDeviceAsync(_userContext.UserId, entity.DeviceId.Value, DeviceAccessPermission.Download, _userContext.IsAdmin))
            {
                throw new UnauthorizedAccessException("You don't have access to this recording's device");
            }

            return await base.DeleteAsync(id);
        }

        protected override IQueryable<Database.Recording> AddFilter(IQueryable<Database.Recording> query, RecordingSearchObject search = null)
        {
            if (!_userContext.IsAdmin)
            {
                var userId = _userContext.UserId;
                query = query.Where(x => x.DeviceId.HasValue &&
                    _context.UserDeviceAccesses.Any(a => a.UserId == userId && a.DeviceId == x.DeviceId));
            }

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

        protected override IQueryable<Database.Recording> AddInclude(IQueryable<Database.Recording> query, RecordingSearchObject search = null)
        {
            return query.Include(x => x.Device).Include(x => x.RecordingStatus).Include(x => x.RecordingType);
        }
    }
}
