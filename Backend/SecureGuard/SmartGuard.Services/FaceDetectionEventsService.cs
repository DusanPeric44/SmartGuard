using Mapster;
using MassTransit;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
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
        private readonly UserManager<ApplicationUser> _userManager;

        public FaceDetectionEventsService(SmartGuardContext context, IPublishEndpoint publishEndpoint, IFileStorageService fileStorage, ILogger<FaceDetectionEventsService> logger, UserManager<ApplicationUser> userManager) : base(context)
        {
            _publishEndpoint = publishEndpoint;
            _fileStorage = fileStorage;
            _logger = logger;
            _userManager = userManager;
        }

        public override async Task<Model.DTOs.FaceDetectionEvent> InsertAsync(FaceDetectionEventInsertRequest insert)
        {
            try
            {
                var created = await base.InsertAsync(insert);
                _logger.LogAuditSuccess("FaceDetectionEventCreated", $"FaceDetectionEvent:{created.Id}", $"DeviceId={insert.DeviceId}; PersonId={insert.PersonId}; FaceId={insert.FaceId}; Timestamp={insert.Timestamp:O}; Image={insert.Image}");
                return created;
            }
            catch (Exception ex)
            {
                _logger.LogAuditFailed("FaceDetectionEventCreated", "FaceDetectionEvent", $"DeviceId={insert.DeviceId}; PersonId={insert.PersonId}; FaceId={insert.FaceId}; Timestamp={insert.Timestamp:O}; Image={insert.Image}", ex);
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
                    _logger.LogAuditSuccess("FaceDetectionEventUpdated", $"FaceDetectionEvent:{id}", $"DeviceId={update.DeviceId}; PersonId={update.PersonId}; FaceId={update.FaceId}; Timestamp={timestamp}; Image={update.Image}");
                }
                return updated;
            }
            catch (Exception ex)
            {
                var timestamp = update.Timestamp.HasValue ? update.Timestamp.Value.ToString("O") : string.Empty;
                _logger.LogAuditFailed("FaceDetectionEventUpdated", $"FaceDetectionEvent:{id}", $"DeviceId={update.DeviceId}; PersonId={update.PersonId}; FaceId={update.FaceId}; Timestamp={timestamp}; Image={update.Image}", ex);
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

        public async Task<Model.DTOs.FaceDetectionEvent> DetectAsync(int deviceId, int faceId, string deviceToken, byte[] jpegBytes)
        {
            var requestedFaceId = faceId;

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

            var createdKnownPerson = false;
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
                    FaceId = faceId--,
                    DetectionCount = 1
                };

                createdKnownPerson = true;
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
                createdKnownPerson = false;

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

            _logger.LogAuditSuccess("FaceDetectionEventCreated", $"FaceDetectionEvent:{entity.Id}", $"DeviceId={deviceId}; FaceId={requestedFaceId}; PersonId={entity.PersonId}; Image={imageUrl}; Timestamp={timestamp:O}");
            if (createdKnownPerson)
            {
                _logger.LogAuditSuccess("KnownPersonAutoCreatedFromDetection", $"KnownPerson:{knownPerson.Id}", $"DeviceId={deviceId}; FaceId={requestedFaceId}; PersonId={knownPerson.Id}");

                var pendingStatusId = await _context.AlertStatuses.Where(x => x.Name == "Pending").Select(x => x.Id).SingleAsync();
                var intruderTypeId = await _context.AlertTypes.Where(x => x.Name == "IntruderDetected").Select(x => x.Id).SingleAsync();

                var alert = new Database.Alert
                {
                    TypeId = intruderTypeId,
                    StatusId = pendingStatusId,
                    Description = $"Intruder detected on {device.Name} at {timestamp:O} (faceId={requestedFaceId}).",
                    DeviceId = deviceId,
                    LinkedEventId = entity.Id,
                    ConfirmedByUserId = null
                };

                _context.Alerts.Add(alert);

                var adminUsers = await _userManager.GetUsersInRoleAsync("Admin");
                var homeOwnerUsers = await _userManager.GetUsersInRoleAsync("HomeOwner");

                var targetUsers = adminUsers
                    .Concat(homeOwnerUsers)
                    .Where(x => !x.IsDeleted)
                    .GroupBy(x => x.Id)
                    .Select(g => g.First())
                    .ToList();

                if (targetUsers.Count > 0)
                {
                    var targetUserIds = targetUsers.Select(x => x.Id).ToList();
                    var existingUserIds = await _context.UserNotificationPreferences
                        .Where(x => x.PersonId == knownPerson.Id && targetUserIds.Contains(x.UserId))
                        .Select(x => x.UserId)
                        .ToListAsync();

                    var preferences = targetUsers
                        .Where(u => !existingUserIds.Contains(u.Id))
                        .Select(u => new Database.UserNotificationPreference
                        {
                            UserId = u.Id,
                            PersonId = knownPerson.Id,
                            Enabled = true
                        })
                        .ToList();

                    if (preferences.Count > 0)
                    {
                        _context.UserNotificationPreferences.AddRange(preferences);
                    }
                }
                await _context.SaveChangesAsync();
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
