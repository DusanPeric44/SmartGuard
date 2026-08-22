using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Options;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    /// <summary>
    /// Authorizes reads of the private /uploads area. FileStorageService already blocks path
    /// traversal, but that only proves a path is inside the uploads root - it says nothing about
    /// whether this caller may see it. Every served path must map back to a row the caller owns or
    /// has device access to.
    /// </summary>
    public class FileAccessService : IFileAccessService
    {
        private readonly SmartGuardContext _context;
        private readonly IUserContext _userContext;
        private readonly IDeviceAccessService _deviceAccessService;
        private readonly FileStorageOptions _options;

        public FileAccessService(
            SmartGuardContext context,
            IUserContext userContext,
            IDeviceAccessService deviceAccessService,
            IOptions<FileStorageOptions> options)
        {
            _context = context;
            _userContext = userContext;
            _deviceAccessService = deviceAccessService;
            _options = options.Value;
        }

        public async Task<bool> CanViewAsync(string urlPath)
        {
            if (string.IsNullOrWhiteSpace(urlPath))
            {
                return false;
            }

            var normalized = Normalize(urlPath);

            // Report PDFs are never served from here, not even for admins: the only authorized route
            // is ReportsController.Download, which checks report ownership. Allowing them here would
            // reopen that check to anyone holding a FileUrl.
            if (IsUnderReports(normalized))
            {
                return false;
            }

            if (_userContext.IsAdmin)
            {
                return true;
            }

            var userId = _userContext.UserId;
            if (string.IsNullOrEmpty(userId))
            {
                return false;
            }

            // Known-person photos: the KnownPersons table is global rather than per-household, and
            // both clients list it for every authenticated user, so the photo follows that same rule.
            if (await _context.KnownPersons.AnyAsync(x => x.Picture == normalized))
            {
                return true;
            }

            // Face captures: readable only by users assigned to the camera that produced them.
            var accessibleDeviceIds = await _deviceAccessService.GetAccessibleDeviceIdsAsync(userId);
            if (accessibleDeviceIds.Count == 0)
            {
                return false;
            }

            return await _context.FaceDetectionEvents.AnyAsync(x =>
                x.Image == normalized &&
                x.DeviceId.HasValue &&
                accessibleDeviceIds.Contains(x.DeviceId.Value));
        }

        /// <summary>
        /// Strips any query/fragment so the value compares equal to the URL stored on the entity,
        /// mirroring what FileStorageService.ResolvePhysicalPath does before touching disk.
        /// </summary>
        private static string Normalize(string urlPath)
        {
            return urlPath.Split('?', '#')[0].Trim();
        }

        private bool IsUnderReports(string normalized)
        {
            var prefix = (_options.UrlPrefix ?? "/uploads").TrimEnd('/');
            var subfolder = (_options.ReportsSubfolder ?? "reports").Trim('/');
            var reportsPrefix = $"{prefix}/{subfolder}/";

            return normalized.Replace(@"\", "/")
                .StartsWith(reportsPrefix, StringComparison.OrdinalIgnoreCase);
        }
    }
}
