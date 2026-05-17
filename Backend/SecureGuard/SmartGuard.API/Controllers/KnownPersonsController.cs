using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model;
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

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public override async Task<KnownPerson> Update(int id, [FromBody] KnownPersonUpdateRequest update)
        {
            return await base.Update(id, update);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public override async Task<bool> Delete(int id)
        {
            return await base.Delete(id);
        }

        [HttpGet("search")]
        public async Task<PagedResult<KnownPerson>> Search([FromQuery] KnownPersonSearchObject? search = null, [FromQuery] string? term = null)
        {
            search ??= new KnownPersonSearchObject();

            if (!string.IsNullOrWhiteSpace(term))
            {
                search.Term = term;
            }

            return await _service.GetAsync(search);
        }
    }
}
