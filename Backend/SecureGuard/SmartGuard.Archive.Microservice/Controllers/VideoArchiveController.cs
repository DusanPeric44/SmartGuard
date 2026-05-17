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
        private readonly IWebHostEnvironment _environment;
        private readonly ILogger<VideoArchiveController> _logger;

        public VideoArchiveController(ArchiveDbContext context, IWebHostEnvironment environment, ILogger<VideoArchiveController> logger)
        {
            _context = context;
            _environment = environment;
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

        [HttpGet("download/{fileName}")]
        public IActionResult Download(string fileName)
        {
            var safeFileName = Path.GetFileName(fileName ?? string.Empty);
            if (string.IsNullOrWhiteSpace(safeFileName) || !string.Equals(safeFileName, fileName, StringComparison.Ordinal))
            {
                return BadRequest("Invalid file name.");
            }

            var physicalPath = Path.Combine(_environment.ContentRootPath, "uploads", "videos", safeFileName);
            if (!System.IO.File.Exists(physicalPath))
            {
                return NotFound();
            }

            return PhysicalFile(physicalPath, "application/octet-stream", safeFileName, enableRangeProcessing: true);
        }
    }
}
