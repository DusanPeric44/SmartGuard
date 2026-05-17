using Mapster;
using MassTransit;
using Microsoft.EntityFrameworkCore;
using SmartGuard.Model.Events;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class FaceDetectionEventsService : BaseCRUDService<Model.DTOs.FaceDetectionEvent, Database.FaceDetectionEvent, FaceDetectionEventSearchObject, FaceDetectionEventInsertRequest, FaceDetectionEventUpdateRequest>, IFaceDetectionEventsService
    {
        private readonly IPublishEndpoint _publishEndpoint;
        private readonly IFileStorageService _fileStorage;

        public FaceDetectionEventsService(SmartGuardContext context, IPublishEndpoint publishEndpoint, IFileStorageService fileStorage) : base(context)
        {
            _publishEndpoint = publishEndpoint;
            _fileStorage = fileStorage;
        }

        public async Task<Model.DTOs.FaceDetectionEvent> DetectAsync(int deviceId, int faceId, string deviceToken, byte[] jpegBytes)
        {
            if (string.IsNullOrWhiteSpace(deviceToken))
            {
                throw new UnauthorizedAccessException();
            }

            if (jpegBytes == null || jpegBytes.Length == 0)
            {
                throw new ArgumentException("Image is required");
            }

            if (jpegBytes.Length > 2_500_000)
            {
                throw new ArgumentException("Image too large");
            }

            var device = await _context.Devices.AsNoTracking().SingleOrDefaultAsync(d => d.Id == deviceId);
            if (device == null || device.ApiKey != deviceToken)
            {
                throw new UnauthorizedAccessException();
            }

            var timestamp = DateTime.UtcNow;
            var imageUrl = await _fileStorage.SaveImageAsync(jpegBytes, ".jpg");

            var knownPerson = await _context.KnownPersons.SingleOrDefaultAsync(x => x.FaceId == faceId);
            if (knownPerson != null)
            {
                knownPerson.DetectionCount += 1;
            }
            else
            {
                var n = await _context.KnownPersons.CountAsync() + 1;
                knownPerson = new Database.KnownPerson
                {
                    FirstName = "Intruder",
                    LastName = n.ToString(),
                    Description = string.Empty,
                    Picture = imageUrl,
                    FaceId = faceId,
                    DetectionCount = 1
                };

                await _context.KnownPersons.AddAsync(knownPerson);
            }

            var entity = new Database.FaceDetectionEvent
            {
                DeviceId = deviceId,
                FaceId = faceId,
                Person = knownPerson,
                Image = imageUrl,
                Timestamp = timestamp,
                Embedding = Array.Empty<byte>()
            };

            try
            {
                await _context.FaceDetectionEvents.AddAsync(entity);
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException) when (entity.Id == 0)
            {
                _context.ChangeTracker.Clear();

                knownPerson = await _context.KnownPersons.SingleOrDefaultAsync(x => x.FaceId == faceId);
                if (knownPerson == null)
                {
                    throw;
                }

                knownPerson.DetectionCount += 1;

                var retryEntity = new Database.FaceDetectionEvent
                {
                    DeviceId = deviceId,
                    FaceId = faceId,
                    Person = knownPerson,
                    Image = imageUrl,
                    Timestamp = timestamp,
                    Embedding = Array.Empty<byte>()
                };

                await _context.FaceDetectionEvents.AddAsync(retryEntity);
                await _context.SaveChangesAsync();

                entity = retryEntity;
            }

            var userIds = await _context.UserDeviceAccesses
                .Where(x => x.DeviceId == deviceId)
                .Select(x => x.UserId)
                .Distinct()
                .ToListAsync();

            if (userIds.Count > 0)
            {
                var tokens = await _context.UserPushTokens
                    .Where(t => userIds.Contains(t.UserId))
                    .Select(t => t.Token)
                    .ToListAsync();

                if (tokens.Count > 0)
                {
                    var title = "SmartGuard - Face detected";
                    var message = $"Face detected on {device.Name} at {timestamp:O} (faceId={faceId}).";

                    foreach (var token in tokens.Distinct())
                    {
                        if (string.IsNullOrWhiteSpace(token)) continue;

                        await _publishEndpoint.Publish<ISendNotificationEvent>(new
                        {
                            Title = title,
                            Message = message,
                            UserId = (string?)null,
                            TargetDeviceToken = token,
                            EmailAddress = (string?)null,
                            SendPush = true,
                            SendEmail = false
                        });
                    }
                }
            }

            return entity.Adapt<Model.DTOs.FaceDetectionEvent>();
        }
    }
}
