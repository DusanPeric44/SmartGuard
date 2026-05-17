using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class UserNotificationPreferencesController : ControllerBase
    {
        private readonly IUserNotificationPreferencesService _service;

        public UserNotificationPreferencesController(IUserNotificationPreferencesService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<PagedResult<UserNotificationPreference>> Get([FromQuery] UserNotificationPreferenceSearchObject search = null)
        {
            return await _service.GetAsync(search);
        }

        [HttpPut("{personId}")]
        public async Task<ActionResult<UserNotificationPreference>> UpdateEnabled(int personId, [FromBody] UserNotificationPreferenceUpdateRequest request)
        {
            var result = await _service.UpdateEnabledAsync(personId, request.Enabled);
            if (result == null)
            {
                return NotFound();
            }

            return Ok(result);
        }
    }
}
