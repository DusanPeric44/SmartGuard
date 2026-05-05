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
    }
}
