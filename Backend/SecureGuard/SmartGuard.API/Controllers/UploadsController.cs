using System.IO;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model.Interfaces;

namespace SmartGuard.API.Controllers
{
    [ApiController]
    [Route("uploads")]
    [Authorize]
    public class UploadsController : ControllerBase
    {
        private readonly IFileStorageService _fileStorage;

        public UploadsController(IFileStorageService fileStorage)
        {
            _fileStorage = fileStorage;
        }

        [HttpGet("{**path}")]
        public async Task<IActionResult> Get(string path)
        {
            try
            {
                var urlPath = "/uploads/" + (path ?? string.Empty);
                var (stream, contentType) = await _fileStorage.OpenReadAsync(urlPath);
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
    }
}

