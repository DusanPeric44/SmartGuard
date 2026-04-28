using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class FaceDetectionEventsController : BaseCRUDController<FaceDetectionEvent, FaceDetectionEventSearchObject, FaceDetectionEventInsertRequest, FaceDetectionEventUpdateRequest>
    {
        public FaceDetectionEventsController(IFaceDetectionEventsService service) : base(service)
        {
        }
    }
}
