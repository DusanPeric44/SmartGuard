using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class UsersController : BaseGetController<UserDto, UsersSearchObject>
    {
        private readonly IUsersService _usersService;

        public UsersController(IUsersService service) : base(service)
        {
            _usersService = service;
        }

        [HttpPost("")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Invite([FromBody] InviteUserRequest request)
        {
            await _usersService.InviteAsync(request);
            return NoContent();
        }

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<UserDto>> Update(string id, [FromBody] UpdateUserRequest request)
        {
            var result = await _usersService.UpdateAsync(id, request);
            return Ok(result);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Delete(string id)
        {
            await _usersService.DeleteAsync(id);
            return NoContent();
        }
    }
}
