using System;
using System.IO;
using System.Threading.Tasks;
using MassTransit;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Events;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class RecordingsController : BaseCRUDController<Recording, RecordingSearchObject, RecordingInsertRequest, RecordingUpdateRequest>
    {
        private readonly IPublishEndpoint _publishEndpoint;

        public RecordingsController(IRecordingsService service, IPublishEndpoint publishEndpoint) : base(service)
        {
            _publishEndpoint = publishEndpoint;
        }

        [HttpPost("{id}/request-clip")]
        public virtual Task<Recording> RequestClip(int id)
        {
            throw new NotImplementedException();
        }

        [HttpDelete("{id}")]
        public override async Task<bool> Delete(int id)
        {
            var recording = await _service.GetByIdAsync(id);
            var deleted = await _crudService.DeleteAsync(id);

            if (!deleted)
            {
                return false;
            }

            var fileUrl = recording?.FilePath ?? string.Empty;
            if (fileUrl.StartsWith("uploading:", StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            var fileName = ExtractFileName(fileUrl);
            if (string.IsNullOrWhiteSpace(fileName))
            {
                return true;
            }

            await _publishEndpoint.Publish<IRecordingFileDeleteRequestedEvent>(new
            {
                RecordingId = id,
                FileUrl = fileUrl,
                FileName = fileName,
                RequestedAtUtc = DateTime.UtcNow
            });

            return true;
        }

        private static string ExtractFileName(string fileUrlOrPath)
        {
            if (string.IsNullOrWhiteSpace(fileUrlOrPath))
            {
                return string.Empty;
            }

            if (Uri.TryCreate(fileUrlOrPath, UriKind.Absolute, out var absoluteUri))
            {
                return Path.GetFileName(absoluteUri.LocalPath);
            }

            if (Uri.TryCreate(fileUrlOrPath, UriKind.Relative, out var relativeUri))
            {
                var path = relativeUri.OriginalString;
                var idx = path.LastIndexOf('/');
                if (idx >= 0 && idx < path.Length - 1)
                {
                    return Path.GetFileName(path[(idx + 1)..]);
                }

                return Path.GetFileName(path);
            }

            return Path.GetFileName(fileUrlOrPath);
        }
    }
}
