using Mapster;
using MassTransit;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SmartGuard.Model;
using SmartGuard.Model.Events;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Audit;
using SmartGuard.Services.Database;
using SmartGuard.Services.Security;

namespace SmartGuard.Services
{
    public class FaceDetectionEventsService : BaseCRUDService<Model.DTOs.FaceDetectionEvent, Database.FaceDetectionEvent, FaceDetectionEventSearchObject, FaceDetectionEventInsertRequest, FaceDetectionEventUpdateRequest>, IFaceDetectionEventsService
    {
        private readonly IPublishEndpoint _publishEndpoint;
        private readonly IFileStorageService _fileStorage;
        private readonly IUserContext _userContext;
        private readonly IDeviceAccessService _deviceAccessService;
        private readonly ILogger<FaceDetectionEventsService> _logger;

        public FaceDetectionEventsService(
            SmartGuardContext context,
            IPublishEndpoint publishEndpoint,
            IFileStorageService fileStorage,
            IUserContext userContext,
            IDeviceAccessService deviceAccessService,
            ILogger<FaceDetectionEventsService> logger) : base(context)
        {
            _publishEndpoint = publishEndpoint;
            _fileStorage = fileStorage;
            _userContext = userContext;
            _deviceAccessService = deviceAccessService;
            _logger = logger;
        }

        public override async Task<Model.DTOs.FaceDetectionEvent> InsertAsync(FaceDetectionEventInsertRequest insert)
        {
            try
            {
                var created = await base.InsertAsync(insert);
                _logger.LogAuditSuccess("FaceDetectionEventCreated", $"FaceDetectionEvent:{created.Id}", $"DeviceId={insert.DeviceId}; PersonId={insert.PersonId}; Score={insert.Score}; Timestamp={insert.Timestamp:O}; Image={insert.Image}");
                return created;
            }
            catch (Exception ex)
            {
                _logger.LogAuditFailed("FaceDetectionEventCreated", "FaceDetectionEvent", $"DeviceId={insert.DeviceId}; PersonId={insert.PersonId}; Score={insert.Score}; Timestamp={insert.Timestamp:O}; Image={insert.Image}", ex);
                throw;
            }
        }

        public override async Task<Model.DTOs.FaceDetectionEvent> UpdateAsync(int id, FaceDetectionEventUpdateRequest update)
        {
            try
            {
                var updated = await base.UpdateAsync(id, update);
                if (updated != null)
                {
                    var timestamp = update.Timestamp.HasValue ? update.Timestamp.Value.ToString("O") : string.Empty;
                    _logger.LogAuditSuccess("FaceDetectionEventUpdated", $"FaceDetectionEvent:{id}", $"DeviceId={update.DeviceId}; PersonId={update.PersonId}; Score={update.Score}; Timestamp={timestamp}; Image={update.Image}");
                }
                return updated;
            }
            catch (Exception ex)
            {
                var timestamp = update.Timestamp.HasValue ? update.Timestamp.Value.ToString("O") : string.Empty;
                _logger.LogAuditFailed("FaceDetectionEventUpdated", $"FaceDetectionEvent:{id}", $"DeviceId={update.DeviceId}; PersonId={update.PersonId}; Score={update.Score}; Timestamp={timestamp}; Image={update.Image}", ex);
                throw;
            }
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            try
            {
                var deleted = await base.DeleteAsync(id);
                if (deleted)
                {
                    _logger.LogAuditSuccess("FaceDetectionEventDeleted", $"FaceDetectionEvent:{id}", $"FaceDetectionEventId={id}");
                }
                return deleted;
            }
            catch (Exception ex)
            {
                _logger.LogAuditFailed("FaceDetectionEventDeleted", $"FaceDetectionEvent:{id}", $"FaceDetectionEventId={id}", ex);
                throw;
            }
        }

        public async Task<Model.DTOs.FaceDetectionEvent> DetectAsync(int deviceId, string deviceToken, byte[] imageBytes, float[] vector)
        {
            if (string.IsNullOrWhiteSpace(deviceToken))
            {
                throw new UnauthorizedAccessException();
            }

            if (imageBytes == null || imageBytes.Length == 0)
            {
                throw new ArgumentException("Image is required");
            }

            if (imageBytes.Length > 2_500_000)
            {
                throw new ArgumentException("Image too large");
            }

            if (vector == null || vector.Length != 128)
            {
                throw new ArgumentException("Vector must have length 128");
            }

            var device = await _context.Devices.AsNoTracking().SingleOrDefaultAsync(d => d.Id == deviceId);
            if (device == null || !ApiKeyHasher.Verify(deviceToken, device.ApiKeyHash))
            {
                throw new UnauthorizedAccessException();
            }

            var timestamp = DateTime.UtcNow;
            var imageUrl = await _fileStorage.SaveImageAsync(imageBytes, ".jpg");
            var normalizedVector = Normalize(vector);
            var embeddingBytes = VectorPacking.PackFloat32(normalizedVector);

            var entity = new Database.FaceDetectionEvent
            {
                DeviceId = deviceId,
                Image = imageUrl,
                Timestamp = timestamp,
                Embedding = embeddingBytes
            };

            await _context.FaceDetectionEvents.AddAsync(entity);
            await _context.SaveChangesAsync();

            _logger.LogAuditSuccess("FaceDetectionEventCreated", $"FaceDetectionEvent:{entity.Id}", $"DeviceId={deviceId}; PersonId={entity.PersonId}; Image={imageUrl}; Timestamp={timestamp:O}");

            await _publishEndpoint.Publish<IVectorMatchRequestedEvent>(new
            {
                FaceDetectionEventId = entity.Id,
                DeviceId = deviceId
            });

            return entity.Adapt<Model.DTOs.FaceDetectionEvent>();
        }

        // GetByIdAsync bypasses AddFilter (the base looks the row up by key), so the detail view
        // needs the same per-device rule the list applies.
        public override async Task<Model.DTOs.FaceDetectionEvent> GetByIdAsync(int id)
        {
            var faceEvent = await base.GetByIdAsync(id);
            if (faceEvent == null)
            {
                return null;
            }

            if (!await _deviceAccessService.CanAccessDeviceAsync(
                    _userContext.UserId, faceEvent.DeviceId, DeviceAccessPermission.View, _userContext.IsAdmin))
            {
                return null;
            }

            return faceEvent;
        }

        protected override IQueryable<Database.FaceDetectionEvent> AddFilter(IQueryable<Database.FaceDetectionEvent> query, FaceDetectionEventSearchObject search = null)
        {
            // Face captures belong to a specific camera, so a caller may only list events from
            // devices they have been granted access to (same rule as GetImagesForPersonAsync).
            if (!_userContext.IsAdmin)
            {
                var currentUserId = _userContext.UserId;
                query = query.Where(x => x.DeviceId.HasValue &&
                    _context.UserDeviceAccesses.Any(a => a.UserId == currentUserId && a.DeviceId == x.DeviceId));
            }

            if (search?.DeviceId.HasValue == true)
            {
                query = query.Where(x => x.DeviceId == search.DeviceId.Value);
            }

            if (search?.PersonId.HasValue == true)
            {
                query = query.Where(x => x.PersonId == search.PersonId.Value);
            }

            if (search?.From.HasValue == true)
            {
                var from = search.From.Value;
                query = query.Where(x => x.Timestamp >= from);
            }

            if (search?.To.HasValue == true)
            {
                var to = search.To.Value;
                query = query.Where(x => x.Timestamp <= to);
            }

            return query;
        }

        public async Task<PagedResult<FaceDetectionEventImage>> GetImagesForPersonAsync(int personId, FaceDetectionEventSearchObject? search = null)
        {
            search ??= new FaceDetectionEventSearchObject();

            var query = _context.FaceDetectionEvents
                .AsNoTracking()
                .Where(x => x.PersonId == personId);

            if (!_userContext.IsAdmin)
            {
                var userId = _userContext.UserId;
                query = query.Where(x => x.DeviceId.HasValue &&
                    _context.UserDeviceAccesses.Any(a => a.UserId == userId && a.DeviceId == x.DeviceId));
            }

            if (search.From.HasValue)
            {
                var from = search.From.Value;
                query = query.Where(x => x.Timestamp >= from);
            }

            if (search.To.HasValue)
            {
                var to = search.To.Value;
                query = query.Where(x => x.Timestamp <= to);
            }

            query = query.OrderByDescending(x => x.Timestamp);

            var count = await query.CountAsync();

            var (page, pageSize) = PaginationHelper.Normalize(search.Page, search.PageSize);
            query = query.Skip((page - 1) * pageSize).Take(pageSize);

            var result = await query
                .Select(x => new FaceDetectionEventImage
                {
                    Id = x.Id,
                    DeviceId = x.DeviceId,
                    Image = x.Image,
                    Timestamp = x.Timestamp,
                    Score = x.Score
                })
                .ToListAsync();

            return new PagedResult<FaceDetectionEventImage>
            {
                Count = count,
                Result = result
            };
        }

        private static float[] Normalize(float[] vector)
        {
            double sum = 0;
            for (int i = 0; i < vector.Length; i++)
            {
                sum += vector[i] * vector[i];
            }

            var norm = Math.Sqrt(sum);
            if (norm == 0)
            {
                return vector;
            }

            var result = new float[vector.Length];
            for (int i = 0; i < vector.Length; i++)
            {
                result[i] = (float)(vector[i] / norm);
            }

            return result;
        }
    }
}
