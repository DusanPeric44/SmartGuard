using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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
        public async Task<ActionResult<FaceDetectionEvent>> Detect()
        {
            if (!Request.Headers.TryGetValue("X-Device-Id", out var deviceIdRaw) ||
                !int.TryParse(deviceIdRaw.ToString(), out var deviceId))
            {
                return BadRequest(new { message = "X-Device-Id header is required" });
            }

            if (!Request.Headers.TryGetValue("X-Face-Id", out var faceIdRaw) ||
                !int.TryParse(faceIdRaw.ToString(), out var faceId))
            {
                return BadRequest(new { message = "X-Face-Id header is required" });
            }

            var deviceToken = Request.Headers["X-Device-Token"].ToString();
            if (string.IsNullOrWhiteSpace(deviceToken))
            {
                return Unauthorized();
            }

            using var ms = new System.IO.MemoryStream();
            await Request.Body.CopyToAsync(ms);
            var jpegBytes = ms.ToArray();

            var created = await _faceDetectionEventsService.DetectAsync(deviceId, faceId, deviceToken, jpegBytes);
            return Ok(created);
        }
    }
}
