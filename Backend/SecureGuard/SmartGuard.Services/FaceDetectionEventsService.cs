using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class FaceDetectionEventsService : BaseCRUDService<Model.DTOs.FaceDetectionEvent, Database.FaceDetectionEvent, FaceDetectionEventSearchObject, FaceDetectionEventInsertRequest, FaceDetectionEventUpdateRequest>, IFaceDetectionEventsService
    {
        public FaceDetectionEventsService(SmartGuardContext context) : base(context)
        {
        }
    }
}
