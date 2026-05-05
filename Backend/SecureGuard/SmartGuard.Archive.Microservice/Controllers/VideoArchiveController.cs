using Microsoft.AspNetCore.Mvc;
using SmartGuard.Archive.Microservice.Database;
using SmartGuard.Services.Database;

namespace SmartGuard.Archive.Microservice.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class VideoArchiveController : ControllerBase
    {
        private readonly ArchiveDbContext _context;
        private readonly ILogger<VideoArchiveController> _logger;

        public VideoArchiveController(ArchiveDbContext context, ILogger<VideoArchiveController> logger)
        {
            _context = context;
            _logger = logger;
        }

        [HttpPost("upload")]
        public async Task<IActionResult> UploadVideo(IFormFile videoFile, [FromForm] int recordingId)
        {
            if (videoFile == null || videoFile.Length == 0)
                return BadRequest("No file uploaded.");

            var recording = await _context.Recordings.FindAsync(recordingId);
            if (recording == null)
                return NotFound("Recording metadata not found.");

            // Logic to save file to storage (e.g., local folder or cloud)
            var filePath = Path.Combine("uploads", videoFile.FileName);
            
            // For skeleton, we just log and update the DB
            _logger.LogInformation("Saving video for recording {Id} to {Path}", recordingId, filePath);

            recording.FilePath = filePath;
            recording.StatusId = 2; // Assuming 2 is 'Completed' or 'Archived'
            
            await _context.SaveChangesAsync();

            return Ok(new { filePath });
        }
    }
}
