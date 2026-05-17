using System.IO;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model.Interfaces;

namespace SmartGuard.API.Controllers
{
    [ApiController]
    [Route("uploads")]
    public class UploadsController : ControllerBase
    {
        private readonly IFileStorageService _fileStorage;

        public UploadsController(IFileStorageService fileStorage)
        {
            _fileStorage = fileStorage;
        }
    }
}
