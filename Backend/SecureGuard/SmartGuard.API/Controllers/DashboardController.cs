using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;

namespace SmartGuard.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class DashboardController : ControllerBase
    {
        private readonly IDashboardService _dashboardService;

        public DashboardController(IDashboardService dashboardService)
        {
            _dashboardService = dashboardService;
        }

        [Authorize(Roles = "Admin")]
        [HttpGet("desktop")]
        public Task<DashboardDesktop> GetDesktop()
        {
            return _dashboardService.GetDesktopAsync();
        }

        [AllowAnonymous]
        [HttpGet("mobile")]
        public Task<DashboardMobile> GetMobile()
        {
            return _dashboardService.GetMobileAsync();
        }
    }
}
