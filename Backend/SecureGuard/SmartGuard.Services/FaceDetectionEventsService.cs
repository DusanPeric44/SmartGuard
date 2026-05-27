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

namespace SmartGuard.Services
{
    public class FaceDetectionEventsService : BaseCRUDService<Model.DTOs.FaceDetectionEvent, Database.FaceDetectionEvent, FaceDetectionEventSearchObject, FaceDetectionEventInsertRequest, FaceDetectionEventUpdateRequest>, IFaceDetectionEventsService
    {
        private readonly IPublishEndpoint _publishEndpoint;
        private readonly IFileStorageService _fileStorage;
        private readonly ILogger<FaceDetectionEventsService> _logger;

        public FaceDetectionEventsService(SmartGuardContext context, IPublishEndpoint publishEndpoint, IFileStorageService fileStorage, ILogger<FaceDetectionEventsService> logger) : base(context)
        {
            _publishEndpoint = publishEndpoint;
            _fileStorage = fileStorage;
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
            if (device == null || device.ApiKey != deviceToken)
            {
                throw new UnauthorizedAccessException();
            }

            var timestamp = DateTime.UtcNow;
            var imageUrl = await _fileStorage.SaveImageAsync(imageBytes, ".jpg");
            var embeddingBytes = VectorPacking.PackFloat32(vector);

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
    }
}
