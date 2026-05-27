using System;
using System.Threading.Tasks;
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
        private readonly IKnownPersonsService _knownPersonsService;

        public KnownPersonsController(IKnownPersonsService service) : base(service)
        {
            _knownPersonsService = service;
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

        [HttpPost("combine")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<KnownPerson>> Combine([FromBody] KnownPersonCombineRequest request)
        {
            if (request.PrimaryPersonId == request.SecondaryPersonId)
                return BadRequest(new { message = "PrimaryPersonId and SecondaryPersonId must be different." });

            try
            {
                var result = await _knownPersonsService.CombineAsync(request.PrimaryPersonId, request.SecondaryPersonId);
                if (result == null) return NotFound();
                return Ok(result);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}
