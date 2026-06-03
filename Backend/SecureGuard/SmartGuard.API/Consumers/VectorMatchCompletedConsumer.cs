using MassTransit;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Distributed;
using SmartGuard.Model;
using SmartGuard.Model.Events;
using SmartGuard.Services.Database;
using SmartGuard.Services.Notifications;

namespace SmartGuard.API.Consumers
{
    public class VectorMatchCompletedConsumer : IConsumer<IVectorMatchCompletedEvent>
    {
        private readonly SmartGuardContext _context;
        private readonly IDistributedCache _cache;
        private readonly NotificationDispatchService _notifications;
        private readonly ILogger<VectorMatchCompletedConsumer> _logger;

        public VectorMatchCompletedConsumer(
            SmartGuardContext context,
            IDistributedCache cache,
            NotificationDispatchService notifications,
            ILogger<VectorMatchCompletedConsumer> logger)
        {
            _context = context;
            _cache = cache;
            _notifications = notifications;
            _logger = logger;
        }

        private async Task CreateIntruderAlertAsync(int deviceId, int faceDetectionEventId, string description, CancellationToken cancellationToken)
        {
            var typeId = await _context.AlertTypes
                .Where(x => x.Name == "IntruderDetected")
                .Select(x => x.Id)
                .SingleOrDefaultAsync(cancellationToken);

            var statusId = await _context.AlertStatuses
                .Where(x => x.Name == "Pending")
                .Select(x => x.Id)
                .SingleOrDefaultAsync(cancellationToken);

            if (typeId == 0 || statusId == 0)
            {
                _logger.LogWarning("AlertType/AlertStatus missing for IntruderDetected/Pending (FaceDetectionEventId={FaceDetectionEventId})", faceDetectionEventId);
                return;
            }

            var alreadyExists = await _context.Alerts.AnyAsync(
                x => x.LinkedEventId == faceDetectionEventId && x.TypeId == typeId,
                cancellationToken);

            if (alreadyExists)
            {
                return;
            }

            _context.Alerts.Add(new Alert
            {
                DeviceId = deviceId,
                TypeId = typeId,
                StatusId = statusId,
                Description = description,
                LinkedEventId = faceDetectionEventId
            });

            await _context.SaveChangesAsync(cancellationToken);
        }

        public async Task Consume(ConsumeContext<IVectorMatchCompletedEvent> context)
        {
            var message = context.Message;
            var faceEvent = await _context.FaceDetectionEvents
                .Include(x => x.Device)
                .SingleOrDefaultAsync(x => x.Id == message.FaceDetectionEventId, context.CancellationToken);
            var knownPerson = await _context.KnownPersons.SingleOrDefaultAsync(x => x.Id == message.MatchedPersonId, context.CancellationToken);

            if (faceEvent == null || faceEvent.DeviceId == null)
            {
                _logger.LogWarning("FaceDetectionEvent not found for vector match result (FaceDetectionEventId={FaceDetectionEventId})", message.FaceDetectionEventId);
                return;
            }

            var deviceId = faceEvent.DeviceId.Value;
            var deviceName = faceEvent.Device?.Name ?? $"Device {deviceId}";

            string? cooldownKey = null;
            int? personId = null;
            if (message.IsMatched && message.MatchedPersonId.HasValue)
            {
                personId = message.MatchedPersonId.Value;
                cooldownKey = $"face-match-notify:{deviceId}:{personId.Value}";

                var cooldownExists = await _cache.GetStringAsync(cooldownKey, context.CancellationToken);
                if (!string.IsNullOrWhiteSpace(cooldownExists))
                {
                    _context.FaceDetectionEvents.Remove(faceEvent);
                    await _context.SaveChangesAsync(context.CancellationToken);
                    return;
                }
            }

            if (faceEvent.Score != message.BestScore)
            {
                faceEvent.Score = message.BestScore;
                await _context.SaveChangesAsync(context.CancellationToken);
            }

            if (message.IsMatched && message.MatchedPersonId.HasValue)
            {
                var personIdValue = personId ?? message.MatchedPersonId.Value;
                var cooldownKeyValue = cooldownKey ?? $"face-match-notify:{deviceId}:{personIdValue}";

                if (faceEvent.PersonId != personIdValue)
                {
                    faceEvent.PersonId = personIdValue;
                    if (knownPerson != null)
                        knownPerson.DetectionCount++;
                    await _context.SaveChangesAsync(context.CancellationToken);
                }

                if (knownPerson != null && string.Equals(knownPerson.FirstName, "Intruder", StringComparison.OrdinalIgnoreCase))
                {
                    var alarmCooldownKey = $"face-match-alarm:{deviceId}:{personIdValue}";
                    var alarmCooldownExists = await _cache.GetStringAsync(alarmCooldownKey, context.CancellationToken);
                    if (string.IsNullOrWhiteSpace(alarmCooldownExists))
                    {
                        var intruderName = knownPerson.FirstName + " " + knownPerson.LastName;
                        var alertDescription = $"Intruder detected: {intruderName} on {deviceName} at {faceEvent.Timestamp:O} (score={message.BestScore:F3}).";
                        await CreateIntruderAlertAsync(deviceId, faceEvent.Id, alertDescription, context.CancellationToken);

                        await _cache.SetStringAsync(
                            alarmCooldownKey,
                            "1",
                            new DistributedCacheEntryOptions { AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(3) },
                            context.CancellationToken);
                    }
                }

                if (knownPerson != null)
                {
                    var embeddingsBytes = await _context.FaceDetectionEvents
                        .AsNoTracking()
                        .Where(e => e.PersonId == personIdValue && e.Embedding != null)
                        .OrderByDescending(e => e.Timestamp)
                        .Select(e => e.Embedding)
                        .Take(20)
                        .ToListAsync(context.CancellationToken);

                    var embeddings = new List<float[]>(embeddingsBytes.Count);
                    foreach (var bytes in embeddingsBytes)
                    {
                        try
                        {
                            var unpacked = VectorPacking.UnpackFloat32(bytes);
                            if (unpacked.Length == 128)
                            {
                                embeddings.Add(unpacked);
                            }
                        }
                        catch (ArgumentException)
                        {
                        }
                    }

                    if (embeddings.Count > 0)
                    {
                        var centroid = ComputeCentroid(embeddings);
                        knownPerson.Embedding = VectorPacking.PackFloat32(centroid);
                        await _context.SaveChangesAsync(context.CancellationToken);
                    }
                }

                var userIdsForMissingPreference = await _context.Users
                    .Where(x => !x.IsDeleted)
                    .Select(x => x.Id)
                    .Distinct()
                    .ToListAsync(context.CancellationToken);

                if (userIdsForMissingPreference.Count == 0)
                {
                    return;
                }

                var existingPreferenceUserIds = await _context.UserNotificationPreferences
                    .Where(x => x.PersonId == personIdValue && userIdsForMissingPreference.Contains(x.UserId))
                    .Select(x => x.UserId)
                    .ToListAsync(context.CancellationToken);

                var existingPreferenceSet = existingPreferenceUserIds.ToHashSet();
                var missingPreferenceUserIds = userIdsForMissingPreference.Where(id => !existingPreferenceSet.Contains(id)).ToList();

                if (missingPreferenceUserIds.Count > 0)
                {
                    var newPreferences = missingPreferenceUserIds.Select(userId => new UserNotificationPreference
                    {
                        UserId = userId,
                        PersonId = personIdValue,
                        Enabled = true
                    });
                    _context.UserNotificationPreferences.AddRange(newPreferences);
                    await _context.SaveChangesAsync(context.CancellationToken);
                }

                var enabledUserIds = await _context.UserNotificationPreferences
                    .Where(x => x.PersonId == personIdValue && userIdsForMissingPreference.Contains(x.UserId) && x.Enabled)
                    .Select(x => x.UserId)
                    .Distinct()
                    .ToListAsync(context.CancellationToken);

                if (enabledUserIds.Count == 0)
                {
                    return;
                }

                var personName = knownPerson == null
                    ? $"Person {personIdValue}"
                    : knownPerson.FirstName + " " + knownPerson.LastName;

                var isIntruder = knownPerson != null &&
                    string.Equals(knownPerson.FirstName, "Intruder", StringComparison.OrdinalIgnoreCase);

                var type = isIntruder ? "IntruderDetected" : "KnownPersonDetected";
                var title = isIntruder
                    ? "SmartGuard - Intruder detected"
                    : "SmartGuard - Known person detected";
                var body = $"{personName} detected on {deviceName} at {faceEvent.Timestamp:O} (score={message.BestScore:F3}).";

                await _notifications.PublishSignalRAsync(enabledUserIds, type, title, body, context.CancellationToken);
                await _notifications.PublishPushToNonAdminsAsync(enabledUserIds, type, title, body, context.CancellationToken);

                await _cache.SetStringAsync(
                    cooldownKeyValue,
                    "1",
                    new DistributedCacheEntryOptions { AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(3) },
                    context.CancellationToken);

                return;
            }

            if (faceEvent.Embedding == null || faceEvent.Embedding.Length == 0)
            {
                return;
            }

            var nextNumber = await _context.KnownPersons.CountAsync(context.CancellationToken) + 1;
            var newPerson = new KnownPerson
            {
                FirstName = "Intruder",
                LastName = nextNumber.ToString(),
                Description = string.Empty,
                Picture = faceEvent.Image,
                FaceId = null,
                DetectionCount = 1,
                Embedding = faceEvent.Embedding
            };

            _context.KnownPersons.Add(newPerson);
            await _context.SaveChangesAsync(context.CancellationToken);

            faceEvent.PersonId = newPerson.Id;
            await _context.SaveChangesAsync(context.CancellationToken);

            var newAlertDescription = $"Unknown face detected on {deviceName} at {faceEvent.Timestamp:O}.";
            await CreateIntruderAlertAsync(deviceId, faceEvent.Id, newAlertDescription, context.CancellationToken);

            var userIds = await _context.Users
                .Where(x => !x.IsDeleted)
                .Select(x => x.Id)
                .Distinct()
                .ToListAsync(context.CancellationToken);

            if (userIds.Count == 0)
            {
                return;
            }

            var existingUserIds = await _context.UserNotificationPreferences
                .Where(x => x.PersonId == newPerson.Id && userIds.Contains(x.UserId))
                .Select(x => x.UserId)
                .ToListAsync(context.CancellationToken);

            var existingSet = existingUserIds.ToHashSet();
            var preferences = userIds.Where(u => !existingSet.Contains(u)).Select(u => new UserNotificationPreference
            {
                UserId = u,
                PersonId = newPerson.Id,
                Enabled = true
            }).ToList();

            if (preferences.Count > 0)
            {
                _context.UserNotificationPreferences.AddRange(preferences);
                await _context.SaveChangesAsync(context.CancellationToken);
            }

            var unknownTitle = "SmartGuard - Intruder detected";
            var unknownBody = $"Unknown face detected on {deviceName} at {faceEvent.Timestamp:O}.";

            await _notifications.PublishSignalRAsync(userIds, "IntruderDetected", unknownTitle, unknownBody, context.CancellationToken);
            await _notifications.PublishPushToNonAdminsAsync(userIds, "IntruderDetected", unknownTitle, unknownBody, context.CancellationToken);
        }

        private static float[] ComputeCentroid(List<float[]> embeddings)
        {
            if (embeddings == null || embeddings.Count == 0)
                throw new ArgumentException("No embeddings");

            var dim = embeddings[0].Length;
            var centroid = new float[dim];

            foreach (var emb in embeddings)
            {
                for (int i = 0; i < dim; i++)
                {
                    centroid[i] += emb[i];
                }
            }

            for (int i = 0; i < dim; i++)
            {
                centroid[i] /= embeddings.Count;
            }

            return Normalize(centroid);
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
                return vector;

            var result = new float[vector.Length];

            for (int i = 0; i < vector.Length; i++)
            {
                result[i] = (float)(vector[i] / norm);
            }

            return result;
        }
    }
}
