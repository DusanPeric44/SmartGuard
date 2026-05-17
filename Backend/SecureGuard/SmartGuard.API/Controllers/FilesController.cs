using System.IO;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model.Interfaces;

namespace SmartGuard.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class FilesController : ControllerBase
    {
        private readonly IFileStorageService _fileStorage;

        public FilesController(IFileStorageService fileStorage)
        {
            _fileStorage = fileStorage;
        }

        [HttpPost("images")]
        public async Task<ActionResult<object>> UploadImage(IFormFile file)
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest();
            }

            if (file.ContentType == null || !file.ContentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase))
            {
                return BadRequest();
            }

            var extension = Path.GetExtension(file.FileName);
            if (string.IsNullOrWhiteSpace(extension))
            {
                extension = file.ContentType.ToLowerInvariant() switch
                {
                    "image/jpeg" => ".jpg",
                    "image/png" => ".png",
                    "image/webp" => ".webp",
                    _ => string.Empty
                };
            }

            if (string.IsNullOrWhiteSpace(extension))
            {
                return BadRequest();
            }

            using var ms = new MemoryStream();
            await file.CopyToAsync(ms);
            var url = await _fileStorage.SaveImageAsync(ms.ToArray(), extension);
            return Ok(new { url });
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

