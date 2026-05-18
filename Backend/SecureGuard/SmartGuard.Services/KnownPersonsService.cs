using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;
using SmartGuard.Services.Audit;
using Microsoft.Extensions.Logging;

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

            var faceId = person.FaceId;
            if (faceId.HasValue)
            {
                var relatedEvents = await _context.FaceDetectionEvents
                    .Where(e => e.FaceId == faceId.Value || e.PersonId == id)
                    .ToListAsync();

                if (relatedEvents.Count > 0)
                {
                    _context.FaceDetectionEvents.RemoveRange(relatedEvents);
                }
            }
            else
            {
                var relatedEvents = await _context.FaceDetectionEvents
                    .Where(e => e.PersonId == id)
                    .ToListAsync();

                if (relatedEvents.Count > 0)
                {
                    _context.FaceDetectionEvents.RemoveRange(relatedEvents);
                }
            }

            _context.KnownPersons.Remove(person);
            await _context.SaveChangesAsync();
            await tx.CommitAsync();
            _logger.LogAuditSuccess("KnownPersonDeleted", $"KnownPerson:{id}", $"{person.FirstName} {person.LastName}".Trim());
            return true;
        }
    }
}
