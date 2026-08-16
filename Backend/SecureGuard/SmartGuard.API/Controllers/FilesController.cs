using System.IO;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model.Interfaces;
using SmartGuard.Services.Files;

namespace SmartGuard.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class FilesController : ControllerBase
    {
        private const long MaxImageSizeBytes = 5 * 1024 * 1024;

        private readonly IFileStorageService _fileStorage;

        public FilesController(IFileStorageService fileStorage)
        {
            _fileStorage = fileStorage;
        }

        [HttpPost("images")]
        [RequestSizeLimit(MaxImageSizeBytes)]
        public async Task<ActionResult<object>> UploadImage(IFormFile file)
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest(new { message = "File is required." });
            }

            if (file.Length > MaxImageSizeBytes)
            {
                return BadRequest(new { message = "File exceeds the maximum allowed size of 5MB." });
            }

            using var ms = new MemoryStream();
            await file.CopyToAsync(ms);
            var bytes = ms.ToArray();

            // Ignore the client-supplied Content-Type/filename entirely - they're attacker-controlled.
            // Only the actual file signature decides what we store and under which extension.
            var extension = ImageSignatureDetector.DetectExtension(bytes);
            if (extension == null)
            {
                return BadRequest(new { message = "Unsupported or invalid image file. Only JPEG, PNG and WEBP are allowed." });
            }

            var url = await _fileStorage.SaveImageAsync(bytes, extension);
            return Ok(new { url });
        }

        [HttpGet("view")]
        public async Task<IActionResult> View([FromQuery] string url)
        {
            if (string.IsNullOrWhiteSpace(url))
            {
                return BadRequest();
            }

            try
            {
                var (stream, contentType) = await _fileStorage.OpenReadAsync(url);
                return File(stream, contentType);
            }
            catch (FileNotFoundException)
            {
                return NotFound();
            }
            catch (ArgumentException)
            {
                return BadRequest();
            }
        }

        [HttpDelete]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Delete([FromQuery] string url)
        {
            if (string.IsNullOrWhiteSpace(url))
            {
                return BadRequest();
            }

            await _fileStorage.DeleteAsync(url);
            return Ok();
        }
    }
}

