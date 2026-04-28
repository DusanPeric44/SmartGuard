using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class KnownPersonsController : BaseCRUDController<KnownPerson, KnownPersonSearchObject, KnownPersonInsertRequest, KnownPersonUpdateRequest>
    {
        public KnownPersonsController(IKnownPersonsService service) : base(service)
        {
        }
    }
}
