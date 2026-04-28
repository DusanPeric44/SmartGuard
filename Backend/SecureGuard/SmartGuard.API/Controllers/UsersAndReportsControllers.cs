using SmartGuard.Model.Interfaces;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class ReportsController : BaseGetController<object, BaseSearchObject>
    {
        public ReportsController(IReportsService service) : base(service)
        {
        }
    }
}
