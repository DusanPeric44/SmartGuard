using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class AlertsService : BaseCRUDService<Model.DTOs.Alert, Database.Alert, AlertSearchObject, AlertInsertRequest, AlertUpdateRequest>, IAlertsService
    {
        public AlertsService(SmartGuardContext context) : base(context)
        {
        }
    }
}
