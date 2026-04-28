using SmartGuard.Model.DTOs;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.Model.Interfaces
{
    public interface IAlertsService : IBaseCRUDService<Alert, AlertSearchObject, AlertInsertRequest, AlertUpdateRequest>
    {
    }
}
