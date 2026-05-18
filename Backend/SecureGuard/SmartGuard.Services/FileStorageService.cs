using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.Extensions.Options;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Options;

namespace SmartGuard.Services
{
    public class FileStorageService : IFileStorageService
    {
        private readonly FileStorageOptions _options;

        public FileStorageService(IOptions<FileStorageOptions> options)
        {
            _options = options.Value;
        }

        public async Task<string> SaveImageAsync(byte[] bytes, string extension)
        {
            if (bytes == null || bytes.Length == 0)
            {
                throw new ArgumentException("File content is required", nameof(bytes));
            }

            if (string.IsNullOrWhiteSpace(_options.UploadsRootPath))
            {
                throw new InvalidOperationException("FileStorageOptions.UploadsRootPath is not configured.");
            }

            extension = NormalizeExtension(extension);

            var fileName = $"{Guid.NewGuid():N}{extension}";
            var relativePath = Path.Combine(_options.ImagesSubfolder, fileName);
            var physicalPath = Path.Combine(_options.UploadsRootPath, relativePath);

            Directory.CreateDirectory(Path.GetDirectoryName(physicalPath)!);
            await File.WriteAllBytesAsync(physicalPath, bytes);

            var urlPrefix = NormalizeUrlPrefix(_options.UrlPrefix);
            var urlPath = $"{urlPrefix}/{relativePath.Replace('\\', '/')}";
            return urlPath;
        }

        public async Task<string> SaveFileAsync(byte[] bytes, string extension, string? subfolder = null)
        {
            if (bytes == null || bytes.Length == 0)
            {
                throw new ArgumentException("File content is required", nameof(bytes));
            }

            if (string.IsNullOrWhiteSpace(_options.UploadsRootPath))
            {
                throw new InvalidOperationException("FileStorageOptions.UploadsRootPath is not configured.");
            }

            extension = NormalizeExtension(extension);
            subfolder = string.IsNullOrWhiteSpace(subfolder) ? _options.ReportsSubfolder : subfolder.Trim();

            var fileName = $"{Guid.NewGuid():N}{extension}";
            var relativePath = Path.Combine(subfolder, fileName);
            var physicalPath = Path.Combine(_options.UploadsRootPath, relativePath);

            Directory.CreateDirectory(Path.GetDirectoryName(physicalPath)!);
            await File.WriteAllBytesAsync(physicalPath, bytes);

            var urlPrefix = NormalizeUrlPrefix(_options.UrlPrefix);
            var urlPath = $"{urlPrefix}/{relativePath.Replace('\\', '/')}";
            return urlPath;
        }

        public Task<(Stream Stream, string ContentType)> OpenReadAsync(string urlPath)
        {
            var physicalPath = ResolvePhysicalPath(urlPath);

            if (!File.Exists(physicalPath))
            {
                throw new FileNotFoundException("File not found", physicalPath);
            }

            var contentType = TryGetContentType(physicalPath);
            Stream stream = new FileStream(physicalPath, FileMode.Open, FileAccess.Read, FileShare.Read);
            return Task.FromResult((stream, contentType));
        }

        public Task DeleteAsync(string urlPath)
        {
            var physicalPath = ResolvePhysicalPath(urlPath);
            if (File.Exists(physicalPath))
            {
                File.Delete(physicalPath);
            }

            return Task.CompletedTask;
        }

        private string ResolvePhysicalPath(string urlPath)
        {
            if (string.IsNullOrWhiteSpace(_options.UploadsRootPath))
            {
                throw new InvalidOperationException("FileStorageOptions.UploadsRootPath is not configured.");
            }

            if (string.IsNullOrWhiteSpace(urlPath))
            {
                throw new ArgumentException("urlPath is required", nameof(urlPath));
            }

            var prefix = NormalizeUrlPrefix(_options.UrlPrefix);
            var path = urlPath.Split('?', '#')[0];
            if (path.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
            {
                path = path.Substring(prefix.Length);
            }

            path = path.TrimStart('/');
            path = path.Replace('/', Path.DirectorySeparatorChar);

            var rootFullPath = Path.GetFullPath(_options.UploadsRootPath);
            var candidateFullPath = Path.GetFullPath(Path.Combine(rootFullPath, path));
            if (!candidateFullPath.StartsWith(rootFullPath, StringComparison.OrdinalIgnoreCase))
            {
                throw new ArgumentException("Invalid urlPath", nameof(urlPath));
            }

            return candidateFullPath;
        }

        private string TryGetContentType(string physicalPath)
        {
            var ext = Path.GetExtension(physicalPath)?.ToLowerInvariant();
            return ext switch
            {
                ".jpg" => "image/jpeg",
                ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                ".webp" => "image/webp",
                ".pdf" => "application/pdf",
                _ => "application/octet-stream"
            };
        }

        private static string NormalizeExtension(string extension)
        {
            extension = extension.Trim();
            if (!extension.StartsWith('.'))
            {
                extension = "." + extension;
            }

            return extension.ToLowerInvariant();
        }

        private static string NormalizeUrlPrefix(string urlPrefix)
        {
            urlPrefix = (urlPrefix ?? string.Empty).Trim();
            if (string.IsNullOrEmpty(urlPrefix))
            {
                return "/uploads";
            }

            if (!urlPrefix.StartsWith('/'))
            {
                urlPrefix = "/" + urlPrefix;
            }

            return urlPrefix.TrimEnd('/');
        }
    }
}
