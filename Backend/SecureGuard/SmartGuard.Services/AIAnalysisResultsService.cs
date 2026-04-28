using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class AIAnalysisResultsService : BaseCRUDService<Model.DTOs.AIAnalysisResult, Database.AIAnalysisResult, AIAnalysisResultSearchObject, AIAnalysisResultInsertRequest, AIAnalysisResultUpdateRequest>, IAIAnalysisResultsService
    {
        public AIAnalysisResultsService(SmartGuardContext context) : base(context)
        {
        }
    }
}
