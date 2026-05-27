using Mapster;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SmartGuard.Model;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Audit;
using SmartGuard.Services.Database;
using System.Collections;

namespace SmartGuard.Services
{
    public class KnownPersonsService : BaseCRUDService<Model.DTOs.KnownPerson, Database.KnownPerson, KnownPersonSearchObject, KnownPersonInsertRequest, KnownPersonUpdateRequest>, IKnownPersonsService
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ILogger<KnownPersonsService> _logger;

        public KnownPersonsService(SmartGuardContext context, UserManager<ApplicationUser> userManager, ILogger<KnownPersonsService> logger) : base(context)
        {
            _userManager = userManager;
            _logger = logger;
        }

        protected override IQueryable<Database.KnownPerson> AddFilter(IQueryable<Database.KnownPerson> query, KnownPersonSearchObject search = null)
        {
            if (!string.IsNullOrWhiteSpace(search?.Term))
            {
                var term = search.Term.Trim();
                query = query.Where(x =>
                    x.FirstName.Contains(term) ||
                    x.LastName.Contains(term) ||
                    x.Description.Contains(term));
            }

            return query;
        }

        public override async Task<Model.DTOs.KnownPerson> InsertAsync(KnownPersonInsertRequest insert)
        {
            await using var tx = await _context.Database.BeginTransactionAsync();

            var person = await base.InsertAsync(insert);

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
                var preferences = targetUsers.Select(u => new Database.UserNotificationPreference
                {
                    UserId = u.Id,
                    PersonId = person.Id,
                    Enabled = true
                });

                _context.UserNotificationPreferences.AddRange(preferences);
                await _context.SaveChangesAsync();
            }

            await tx.CommitAsync();
            _logger.LogAuditSuccess("KnownPersonCreated", $"KnownPerson:{person.Id}", $"{person.FirstName} {person.LastName}".Trim());
            return person;
        }

        public override async Task<Model.DTOs.KnownPerson> UpdateAsync(int id, KnownPersonUpdateRequest update)
        {
            try
            {
                var updated = await base.UpdateAsync(id, update);
                if (updated != null)
                {
                    _logger.LogAuditSuccess("KnownPersonUpdated", $"KnownPerson:{id}", $"{updated.FirstName} {updated.LastName}".Trim());
                }
                return updated;
            }
            catch (Exception ex)
            {
                _logger.LogAuditFailed("KnownPersonUpdated", $"KnownPerson:{id}", $"FirstName={update.FirstName}; LastName={update.LastName}", ex);
                throw;
            }
        }

        public async Task<bool> UpdatePictureAsync(int id, string picturePath)
        {
            var entity = await _context.KnownPersons.FindAsync(id);
            if (entity == null) return false;

            entity.Picture = picturePath;
            await _context.SaveChangesAsync();
            _logger.LogAuditSuccess("KnownPersonPictureUpdated", $"KnownPerson:{id}", $"Picture={picturePath}");
            return true;
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var person = await _context.KnownPersons.SingleOrDefaultAsync(x => x.Id == id);
            if (person == null) return false;

            await using var tx = await _context.Database.BeginTransactionAsync();

            var relatedPreferences = await _context.UserNotificationPreferences
                .Where(x => x.PersonId == id)
                .ToListAsync();

            if (relatedPreferences.Count > 0)
            {
                _context.UserNotificationPreferences.RemoveRange(relatedPreferences);
            }

            var relatedEvents = await _context.FaceDetectionEvents
                .Where(e => e.PersonId == id)
                .Select(e => new { e.Id })
                .ToListAsync();

            if (relatedEvents.Count > 0)
            {
                var relatedEventIds = relatedEvents.Select(x => x.Id).ToList();

                var relatedAlerts = await _context.Alerts
                    .Where(a => a.LinkedEventId.HasValue && relatedEventIds.Contains(a.LinkedEventId.Value))
                    .ToListAsync();

                foreach (var alert in relatedAlerts)
                {
                    alert.IsDeleted = true;
                    alert.LinkedEventId = null;
                }

                var relatedEventsEntities = await _context.FaceDetectionEvents
                    .Where(e => relatedEventIds.Contains(e.Id))
                    .ToListAsync();

                _context.FaceDetectionEvents.RemoveRange(relatedEventsEntities);
            }

            _context.KnownPersons.Remove(person);
            await _context.SaveChangesAsync();
            await tx.CommitAsync();
            _logger.LogAuditSuccess("KnownPersonDeleted", $"KnownPerson:{id}", $"{person.FirstName} {person.LastName}".Trim());
            return true;
        }

        public async Task<Model.DTOs.KnownPerson?> CombineAsync(int primaryPersonId, int secondaryPersonId)
        {
            if (primaryPersonId == secondaryPersonId)
                throw new ArgumentException("Primary and secondary person must be different.");

            await using var tx = await _context.Database.BeginTransactionAsync();

            try
            {
                var primary = await _context.KnownPersons.SingleOrDefaultAsync(x => x.Id == primaryPersonId);
                var secondary = await _context.KnownPersons.SingleOrDefaultAsync(x => x.Id == secondaryPersonId);

                if (primary == null || secondary == null)
                    return null;

                var isPrimaryIntruder = string.Equals(primary.FirstName, "Intruder", StringComparison.OrdinalIgnoreCase);

                var secondaryEvents = await _context.FaceDetectionEvents
                    .Where(e => e.PersonId == secondaryPersonId)
                    .ToListAsync();

                var secondaryEventIds = secondaryEvents.Select(e => e.Id).ToList();

                foreach (var e in secondaryEvents)
                {
                    e.PersonId = primaryPersonId;
                }

                primary.DetectionCount += secondary.DetectionCount;

                await _context.SaveChangesAsync();

                if (!isPrimaryIntruder && secondaryEventIds.Count > 0)
                {
                    var relatedAlerts = await _context.Alerts
                        .Where(a => a.LinkedEventId.HasValue && secondaryEventIds.Contains(a.LinkedEventId.Value))
                        .ToListAsync();

                    foreach (var alert in relatedAlerts)
                    {
                        alert.IsDeleted = true;
                        alert.LinkedEventId = null;
                    }

                    await _context.SaveChangesAsync();
                }

                var embeddingsBytes = await _context.FaceDetectionEvents
                    .AsNoTracking()
                    .Where(e => e.PersonId == primaryPersonId && e.Embedding != null)
                    .OrderByDescending(e => e.Score ?? double.MinValue)
                    .ThenByDescending(e => e.Timestamp)
                    .Select(e => e.Embedding)
                    .Take(20)
                    .ToListAsync();

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
                    primary.Embedding = VectorPacking.PackFloat32(centroid);
                    await _context.SaveChangesAsync();
                }

                _context.KnownPersons.Remove(secondary);
                await _context.SaveChangesAsync();

                await tx.CommitAsync();

                _logger.LogAuditSuccess(
                    "KnownPersonsCombined",
                    $"KnownPerson:{primaryPersonId}",
                    $"Secondary={secondaryPersonId}");

                return primary.Adapt<Model.DTOs.KnownPerson>();
            }
            catch (Exception ex)
            {
                _logger.LogAuditFailed(
                    "KnownPersonsCombined",
                    $"KnownPerson:{primaryPersonId}",
                    $"Secondary={secondaryPersonId}",
                    ex);
                await tx.RollbackAsync();
                throw;
            }
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
