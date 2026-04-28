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
    }
}
