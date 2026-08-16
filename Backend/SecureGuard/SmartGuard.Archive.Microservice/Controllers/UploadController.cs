using MassTransit;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model.Events;
using Xabe.FFmpeg;

namespace SmartGuard.Archive.Microservice.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class UploadController : ControllerBase
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;
        private readonly IWebHostEnvironment _environment;
        private readonly IPublishEndpoint _publishEndpoint;

        public UploadController(
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration,
            IWebHostEnvironment environment,
            IPublishEndpoint publishEndpoint)
        {
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
            _environment = environment;
            _publishEndpoint = publishEndpoint;
        }

        [HttpPost("")]
        [AllowAnonymous]
        [DisableRequestSizeLimit]
        public async Task<IActionResult> Upload(CancellationToken cancellationToken)
        {
            if (!Request.Headers.TryGetValue("X-Device-Id", out var deviceIdRaw) ||
                !int.TryParse(deviceIdRaw.ToString(), out var deviceId))
            {
                return BadRequest(new { message = "X-Device-Id header is required" });
            }

            var internalToken = Request.Headers["X-Internal-Token"].ToString();
            var expectedInternalToken = _configuration["Internal:ServiceToken"];
            var isTrustedInternalCaller = !string.IsNullOrWhiteSpace(internalToken)
                && !string.IsNullOrWhiteSpace(expectedInternalToken)
                && internalToken == expectedInternalToken;

            if (!isTrustedInternalCaller)
            {
                // Not a call from our own API server on a user's behalf - must be the device itself,
                // authenticating with its own device token.
                var deviceToken = Request.Headers["X-Device-Token"].ToString();
                if (string.IsNullOrWhiteSpace(deviceToken))
                {
                    return BadRequest(new { message = "X-Device-Token header is required" });
                }

                var apiBaseUrl = _configuration["SmartGuardApi:BaseUrl"];
                if (string.IsNullOrWhiteSpace(apiBaseUrl))
                {
                    return StatusCode(StatusCodes.Status500InternalServerError, new { message = "SmartGuardApi:BaseUrl is not configured" });
                }

                if (!await ValidateDeviceAsync(apiBaseUrl, deviceId, deviceToken, cancellationToken))
                {
                    return Unauthorized();
                }
            }

            var recordingTypeRaw = Request.Headers["X-Recording-Type"].ToString();
            var recordingTypeToken = NormalizeRecordingType(recordingTypeRaw);

            var timestampUtc = DateTime.UtcNow;
            var fileName = $"device_{deviceId}_{recordingTypeToken}_{timestampUtc:yyyyMMddHHmmss}_{Guid.NewGuid():N}.mp4";

            var uploadsPath = Path.Combine(_environment.ContentRootPath, "uploads");
            var videosPath = Path.Combine(uploadsPath, "videos");
            var tempPath = Path.Combine(uploadsPath, "tmp");
            Directory.CreateDirectory(videosPath);
            Directory.CreateDirectory(tempPath);

            var physicalPath = Path.Combine(videosPath, fileName);
            var tempPhysicalPath = Path.Combine(tempPath, $"{Path.GetFileNameWithoutExtension(fileName)}.mjpeg");
            var contentType = "video/mp4";

            await _publishEndpoint.Publish<IRecordingUploadStartedEvent>(new
            {
                DeviceId = deviceId,
                TimestampUtc = timestampUtc,
                FileName = fileName,
                ContentType = contentType
            }, cancellationToken);

            long size = 0;
            try
            {
                await using (var fs = new FileStream(tempPhysicalPath, FileMode.Create, FileAccess.Write, FileShare.None, 1024 * 64, useAsync: true))
                {
                    var buffer = new byte[1024 * 64];
                    while (true)
                    {
                        var read = await Request.Body.ReadAsync(buffer, cancellationToken);
                        if (read == 0) break;

                        await fs.WriteAsync(buffer.AsMemory(0, read), cancellationToken);
                        size += read;
                    }
                }

                await ConvertMjpegToMp4Async(tempPhysicalPath, physicalPath, cancellationToken);
                TryDeleteFile(tempPhysicalPath);
                size = new FileInfo(physicalPath).Length;
                var duration = await GetDurationSecondsAsync(physicalPath, cancellationToken);

                var fileUrl = $"/upload/videos/{fileName}";

                await _publishEndpoint.Publish<IRecordingUploadCompletedEvent>(new
                {
                    DeviceId = deviceId,
                    TimestampUtc = timestampUtc,
                    FileName = fileName,
                    FileUrl = fileUrl,
                    Size = size,
                    Duration = duration,
                    Success = true
                }, cancellationToken);

                return Ok(new { fileName, url = fileUrl, size, duration });
            }
            catch
            {
                TryDeleteFile(tempPhysicalPath);
                TryDeleteFile(physicalPath);

                await _publishEndpoint.Publish<IRecordingUploadCompletedEvent>(new
                {
                    DeviceId = deviceId,
                    TimestampUtc = timestampUtc,
                    FileName = fileName,
                    FileUrl = string.Empty,
                    Size = size,
                    Duration = 0,
                    Success = false
                }, cancellationToken);

                throw;
            }
        }

        private static string NormalizeRecordingType(string raw)
        {
            var value = (raw ?? string.Empty).Trim();
            if (value.Length == 0)
            {
                return "motion";
            }

            value = value.Replace(" ", string.Empty).Replace("-", string.Empty).Replace("_", string.Empty);
            if (string.Equals(value, "motion", StringComparison.OrdinalIgnoreCase))
            {
                return "motion";
            }

            if (string.Equals(value, "facedetected", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(value, "face", StringComparison.OrdinalIgnoreCase))
            {
                return "facedetected";
            }

            if (string.Equals(value, "manual", StringComparison.OrdinalIgnoreCase))
            {
                return "manual";
            }

            return "motion";
        }

        private static async Task ConvertMjpegToMp4Async(string inputPath, string outputPath, CancellationToken cancellationToken)
        {
            if (System.IO.File.Exists(outputPath))
            {
                System.IO.File.Delete(outputPath);
            }

            var conversion = FFmpeg.Conversions.New();
            conversion.AddParameter($"-r 10 -i \"{inputPath}\" -c:v libx264 -pix_fmt yuv420p \"{outputPath}\"");
            await conversion.Start(cancellationToken);
        }

        private static async Task<int> GetDurationSecondsAsync(string path, CancellationToken cancellationToken)
        {
            var mediaInfo = await FFmpeg.GetMediaInfo(path, cancellationToken);
            return (int)Math.Round(mediaInfo.Duration.TotalSeconds);
        }

        private static void TryDeleteFile(string path)
        {
            try
            {
                if (System.IO.File.Exists(path))
                {
                    System.IO.File.Delete(path);
                }
            }
            catch
            {
            }
        }

        private async Task<bool> ValidateDeviceAsync(string apiBaseUrl, int deviceId, string deviceToken, CancellationToken cancellationToken)
        {
            var baseUrl = apiBaseUrl.TrimEnd('/');
            var url = $"{baseUrl}/Devices/validate";

            var client = _httpClientFactory.CreateClient();
            using var request = new HttpRequestMessage(HttpMethod.Get, url);
            request.Headers.Add("X-Device-Id", deviceId.ToString());
            request.Headers.Add("X-Device-Token", deviceToken);

            using var response = await client.SendAsync(request, cancellationToken);
            return response.IsSuccessStatusCode;
        }
    }
}
