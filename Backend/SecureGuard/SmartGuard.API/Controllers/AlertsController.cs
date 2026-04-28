using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class AlertsController : BaseCRUDController<Alert, AlertSearchObject, AlertInsertRequest, AlertUpdateRequest>
    {
        public AlertsController(IAlertsService service) : base(service)
        {
        }

        [HttpPost("{id}/dismiss")]
        public virtual Task<Alert> Dismiss(int id)
        {
            throw new NotImplementedException();
        }
    }
}
