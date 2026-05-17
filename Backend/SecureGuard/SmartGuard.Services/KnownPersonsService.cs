using Microsoft.EntityFrameworkCore;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class KnownPersonsService : BaseCRUDService<Model.DTOs.KnownPerson, Database.KnownPerson, KnownPersonSearchObject, KnownPersonInsertRequest, KnownPersonUpdateRequest>, IKnownPersonsService
    {
        public KnownPersonsService(SmartGuardContext context) : base(context)
        {
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
            // Logic for handling face embedding and picture path could go here
            return await base.InsertAsync(insert);
        }

        public async Task<bool> UpdatePictureAsync(int id, string picturePath)
        {
            var entity = await _context.KnownPersons.FindAsync(id);
            if (entity == null) return false;

            entity.Picture = picturePath;
            await _context.SaveChangesAsync();
            return true;
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var person = await _context.KnownPersons.SingleOrDefaultAsync(x => x.Id == id);
            if (person == null) return false;

            await using var tx = await _context.Database.BeginTransactionAsync();

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
            return true;
        }
    }
}
