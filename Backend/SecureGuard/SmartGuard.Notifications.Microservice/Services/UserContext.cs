using Microsoft.AspNetCore.Http;
using SmartGuard.Model.Interfaces;
using System.Security.Claims;

namespace SmartGuard.Notifications.Microservice.Services
{
    public class UserContext(IHttpContextAccessor httpContextAccessor) : IUserContext
    {
        public string Email => httpContextAccessor.HttpContext?.User?.FindFirstValue(ClaimTypes.NameIdentifier) ?? string.Empty;

        public string UserId => httpContextAccessor.HttpContext?.User?.FindFirstValue("UserId") ?? string.Empty;

        public bool IsAdmin => httpContextAccessor.HttpContext?.User?.IsInRole("Admin") ?? false;
    }
}

