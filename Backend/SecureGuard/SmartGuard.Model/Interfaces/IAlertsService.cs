using System.Threading.Tasks;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.Model.Interfaces
{
    public interface IAlertsService : IBaseCRUDService<Alert, AlertSearchObject, AlertInsertRequest, AlertUpdateRequest>
    {
        Task<Alert> ConfirmAsync(int id);
        Task<Alert> DismissAsync(int id, string dismissalReason);
        Task<Alert> ResolveAsync(int id);
    }
}
