using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class UsersController : BaseGetController<UserDto, UsersSearchObject>
    {
        private readonly IUsersService _usersService;
        private readonly IUserPushTokensService _userPushTokensService;

        public UsersController(IUsersService service, IUserPushTokensService userPushTokensService) : base(service)
        {
            _usersService = service;
            _userPushTokensService = userPushTokensService;
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

        [HttpPut("me")]
        [Authorize]
        public async Task<ActionResult<UserDto>> UpdateMe([FromBody] UpdateProfileRequest request)
        {
            var userId = User.FindFirstValue("UserId");
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var result = await _usersService.UpdateProfileAsync(userId, request);
            return Ok(result);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Delete(string id)
        {
            await _usersService.DeleteAsync(id);
            return NoContent();
        }

        [HttpPost("push-token")]
        [Authorize]
        public async Task<IActionResult> UpsertPushToken([FromBody] UserPushTokenUpsertRequest request)
        {
            await _userPushTokensService.UpsertAsync(request);
            return NoContent();
        }
    }
}
