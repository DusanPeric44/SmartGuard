using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class AIAnalysisResultsController : BaseCRUDController<AIAnalysisResult, AIAnalysisResultSearchObject, AIAnalysisResultInsertRequest, AIAnalysisResultUpdateRequest>
    {
        public AIAnalysisResultsController(IAIAnalysisResultsService service) : base(service)
        {
        }
    }
}
