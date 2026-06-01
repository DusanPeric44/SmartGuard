using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;

namespace SmartGuard.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class MotionDetectionEventsController : ControllerBase
    {
        private readonly IMotionDetectionEventsService _motionDetectionEventsService;

        public MotionDetectionEventsController(IMotionDetectionEventsService motionDetectionEventsService)
        {
            _motionDetectionEventsService = motionDetectionEventsService;
        }

        [HttpPost("detect")]
        [AllowAnonymous]
        public async Task<IActionResult> Detect([FromBody] MotionDetectionDetectRequest request)
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

            var suppressed = await _motionDetectionEventsService.DetectAsync(request.DeviceId, deviceToken);
            return Ok(new { suppressed });
        }
    }
}

