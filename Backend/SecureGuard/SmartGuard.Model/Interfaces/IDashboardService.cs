using System.Threading.Tasks;
using SmartGuard.Model.DTOs;

namespace SmartGuard.Model.Interfaces
{
    public interface IDashboardService
    {
        Task<DashboardDesktop> GetDesktopAsync();
        Task<DashboardMobile> GetMobileAsync();
    }
}
