using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class FaceDetectionEventsController : BaseCRUDController<FaceDetectionEvent, FaceDetectionEventSearchObject, FaceDetectionEventInsertRequest, FaceDetectionEventUpdateRequest>
    {
        private readonly IFaceDetectionEventsService _faceDetectionEventsService;

        public FaceDetectionEventsController(IFaceDetectionEventsService service) : base(service)
        {
            _faceDetectionEventsService = service;
        }

        [HttpPost("detect")]
        [AllowAnonymous]
        public async Task<ActionResult<FaceDetectionEvent>> Detect([FromBody] FaceDetectionVectorDetectRequest request)
        {
            var deviceToken = Request.Headers["X-Device-Token"].ToString();
            if (string.IsNullOrWhiteSpace(deviceToken))
            {
                return Unauthorized();
            }

            if (request == null)
            {
                return BadRequest(new { message = "Request body is required" });
            }

            var created = await _faceDetectionEventsService.DetectAsync(request.DeviceId, deviceToken, request.ImageBytes ?? Array.Empty<byte>(), request.Vector);
            return Ok(created);
        }

        [HttpGet("person/{personId}/images")]
        public async Task<PagedResult<FaceDetectionEventImage>> GetImagesForPerson(int personId, [FromQuery] FaceDetectionEventSearchObject? search = null)
        {
            return await _faceDetectionEventsService.GetImagesForPersonAsync(personId, search);
        }
    }
}
