using System.Collections.Concurrent;
using System.Globalization;
using System.Net.Http.Headers;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SmartGuard.Model;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Options;
using SmartGuard.Services.Database;

namespace SmartGuard.API.Services
{
    public class StreamRecordingManager : IStreamRecordingManager
    {
        private readonly ConcurrentDictionary<string, RecordingSession> _sessions = new(StringComparer.OrdinalIgnoreCase);
        private readonly ConcurrentDictionary<string, ConcurrentDictionary<string, byte>> _deviceKeysByConnection = new(StringComparer.OrdinalIgnoreCase);
        private readonly SemaphoreSlim _startStopLock = new(1, 1);
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IOptionsMonitor<ArchiveOptions> _archiveOptionsMonitor;
        private readonly IConfiguration _configuration;
        private readonly ILogger<StreamRecordingManager> _logger;
        private readonly string _tempRecordingsPath;

        public StreamRecordingManager(
            IServiceScopeFactory scopeFactory,
            IHttpClientFactory httpClientFactory,
            IOptionsMonitor<ArchiveOptions> archiveOptionsMonitor,
            IConfiguration configuration,
            IWebHostEnvironment environment,
            ILogger<StreamRecordingManager> logger)
        {
            _scopeFactory = scopeFactory;
            _httpClientFactory = httpClientFactory;
            _archiveOptionsMonitor = archiveOptionsMonitor;
            _configuration = configuration;
            _logger = logger;

            var uploadsPath = Path.Combine(environment.ContentRootPath, "uploads");
            _tempRecordingsPath = Path.Combine(uploadsPath, "tmp-recordings");
            Directory.CreateDirectory(_tempRecordingsPath);
        }

        public async Task StartAsync(string deviceKey, string userId, string connectionId, CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(deviceKey)) throw new UserException("deviceId is required");
            if (string.IsNullOrWhiteSpace(userId)) throw new UserException("UserId is required");
            if (string.IsNullOrWhiteSpace(connectionId)) throw new UserException("ConnectionId is required");

            await _startStopLock.WaitAsync(cancellationToken);
            try
            {
                await using var scope = _scopeFactory.CreateAsyncScope();
                var db = scope.ServiceProvider.GetRequiredService<SmartGuardContext>();

                if (_sessions.ContainsKey(deviceKey))
                {
                    throw new UserException("Recording already in progress");
                }

                var device = await ResolveDeviceAsync(db, deviceKey, cancellationToken);
                if (device == null)
                {
                    throw new UserException("Device not found");
                }

                var canStream = await db.UserDeviceAccesses
                    .AsNoTracking()
                    .AnyAsync(x => x.UserId == userId && x.DeviceId == device.Id && x.CanStream, cancellationToken);

                if (!canStream)
                {
                    throw new UserException("You don't have permission to stream this device");
                }

                var tempFilePath = Path.Combine(_tempRecordingsPath, $"device_{device.Id}_{DateTime.UtcNow:yyyyMMddHHmmss}_{Guid.NewGuid():N}.mjpeg");
                var stream = new FileStream(tempFilePath, FileMode.CreateNew, FileAccess.Write, FileShare.Read, 1024 * 64, useAsync: true);

                var session = new RecordingSession(
                    deviceKey: deviceKey,
                    deviceId: device.Id,
                    connectionId: connectionId,
                    userId: userId,
                    startedUtc: DateTime.UtcNow,
                    tempFilePath: tempFilePath,
                    stream: stream,
                    writeInterval: GetWriteInterval());

                if (!_sessions.TryAdd(deviceKey, session))
                {
                    await stream.DisposeAsync();
                    TryDeleteFile(tempFilePath);
                    throw new UserException("Recording already in progress");
                }

                _deviceKeysByConnection
                    .GetOrAdd(connectionId, _ => new ConcurrentDictionary<string, byte>(StringComparer.OrdinalIgnoreCase))
                    .TryAdd(deviceKey, 0);
            }
            catch
            {
                throw;
            }
            finally
            {
                _startStopLock.Release();
            }
        }

        public async Task StopAsync(string deviceKey, string reason, CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(deviceKey)) return;

            await _startStopLock.WaitAsync(cancellationToken);
            try
            {
                if (!_sessions.TryRemove(deviceKey, out var session)) return;
                await StopInternalAsync(session, reason, cancellationToken);
            }
            finally
            {
                _startStopLock.Release();
            }
        }

        public async Task<IReadOnlyList<string>> StopByConnectionAsync(string connectionId, string reason, CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(connectionId)) return Array.Empty<string>();
            if (!_deviceKeysByConnection.TryRemove(connectionId, out var set)) return Array.Empty<string>();

            var stopped = new List<string>();
            foreach (var deviceKey in set.Keys)
            {
                if (!_sessions.TryRemove(deviceKey, out var session)) continue;

                try
                {
                    await StopInternalAsync(session, reason, cancellationToken);
                    stopped.Add(deviceKey);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to stop recording for device {DeviceKey} on disconnect", deviceKey);
                }
            }

            return stopped;
        }

        public async Task TryWriteFrameAsync(string deviceKey, byte[] jpegBytes, CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(deviceKey)) return;
            if (jpegBytes == null || jpegBytes.Length == 0) return;
            if (!_sessions.TryGetValue(deviceKey, out var session)) return;
            if (!session.ShouldWriteFrame(DateTime.UtcNow)) return;

            await session.WriteLock.WaitAsync(cancellationToken);
            try
            {
                var now = DateTime.UtcNow;
                if (!session.ShouldWriteFrame(now)) return;

                await session.Stream.WriteAsync(jpegBytes, cancellationToken);
                session.MarkFrameWritten(now);
            }
            finally
            {
                session.WriteLock.Release();
            }
        }

        private async Task StopInternalAsync(RecordingSession session, string reason, CancellationToken cancellationToken)
        {
            if (_deviceKeysByConnection.TryGetValue(session.ConnectionId, out var set))
            {
                set.TryRemove(session.DeviceKey, out _);
                if (set.IsEmpty)
                {
                    _deviceKeysByConnection.TryRemove(session.ConnectionId, out _);
                }
            }

            await session.WriteLock.WaitAsync(cancellationToken);
            try
            {
                await session.Stream.FlushAsync(cancellationToken);
                await session.Stream.DisposeAsync();
            }
            finally
            {
                session.WriteLock.Release();
            }

            try
            {
                await UploadToArchiveAsync(session, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Archive upload failed for device {DeviceId}. Reason={Reason}", session.DeviceId, reason);
                throw;
            }
            finally
            {
                TryDeleteFile(session.TempFilePath);
            }
        }

        private async Task UploadToArchiveAsync(RecordingSession session, CancellationToken cancellationToken)
        {
            var options = _archiveOptionsMonitor.CurrentValue;
            if (string.IsNullOrWhiteSpace(options.BaseUrl))
            {
                throw new InvalidOperationException("ArchiveOptions.BaseUrl is not configured.");
            }

            var baseUrl = options.BaseUrl.TrimEnd('/') + "/";
            if (!Uri.TryCreate(baseUrl, UriKind.Absolute, out var baseUri))
            {
                throw new InvalidOperationException("ArchiveOptions.BaseUrl is not a valid absolute URL.");
            }

            var uploadPath = (options.UploadPath ?? string.Empty).Trim();
            uploadPath = uploadPath.TrimStart('/');
            if (string.IsNullOrWhiteSpace(uploadPath))
            {
                uploadPath = "Upload";
            }

            var client = _httpClientFactory.CreateClient();
            await using var fileStream = new FileStream(session.TempFilePath, FileMode.Open, FileAccess.Read, FileShare.Read, 1024 * 64, useAsync: true);
            using var request = new HttpRequestMessage(HttpMethod.Post, new Uri(baseUri, uploadPath));

            var internalToken = _configuration["Internal:ServiceToken"];
            if (string.IsNullOrWhiteSpace(internalToken))
            {
                throw new InvalidOperationException("Internal:ServiceToken is not configured.");
            }

            request.Headers.Add("X-Device-Id", session.DeviceId.ToString(CultureInfo.InvariantCulture));
            request.Headers.Add("X-Internal-Token", internalToken);
            request.Headers.Add("X-Recording-Type", "Manual");

            request.Content = new StreamContent(fileStream);
            request.Content.Headers.ContentType = new MediaTypeHeaderValue("video/x-motion-jpeg");

            using var response = await client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
            response.EnsureSuccessStatusCode();
        }

        private static void TryDeleteFile(string path)
        {
            try
            {
                if (File.Exists(path))
                {
                    File.Delete(path);
                }
            }
            catch
            {
            }
        }

        private TimeSpan GetWriteInterval()
        {
            var fps = _archiveOptionsMonitor.CurrentValue.RecordingFps;
            if (fps <= 0) fps = 3;
            return TimeSpan.FromMilliseconds(1000d / fps);
        }

        private static async Task<Device?> ResolveDeviceAsync(SmartGuardContext db, string deviceKey, CancellationToken cancellationToken)
        {
            if (int.TryParse(deviceKey, NumberStyles.Integer, CultureInfo.InvariantCulture, out var deviceId) && deviceId > 0)
            {
                return await db.Devices.AsNoTracking().FirstOrDefaultAsync(x => x.Id == deviceId, cancellationToken);
            }

            var mac = deviceKey.Trim();
            if (mac.Length == 0) return null;

            return await db.Devices.AsNoTracking().FirstOrDefaultAsync(x => x.MacAddress == mac, cancellationToken);
        }

        private sealed class RecordingSession
        {
            public string DeviceKey { get; }
            public int DeviceId { get; }
            public string ConnectionId { get; }
            public string UserId { get; }
            public DateTime StartedUtc { get; }
            public string TempFilePath { get; }
            public FileStream Stream { get; }
            public SemaphoreSlim WriteLock { get; } = new(1, 1);

            private readonly TimeSpan _writeInterval;
            private DateTime _lastWrittenUtc;

            public RecordingSession(
                string deviceKey,
                int deviceId,
                string connectionId,
                string userId,
                DateTime startedUtc,
                string tempFilePath,
                FileStream stream,
                TimeSpan writeInterval)
            {
                DeviceKey = deviceKey;
                DeviceId = deviceId;
                ConnectionId = connectionId;
                UserId = userId;
                StartedUtc = startedUtc;
                TempFilePath = tempFilePath;
                Stream = stream;
                _writeInterval = writeInterval <= TimeSpan.Zero ? TimeSpan.FromMilliseconds(333) : writeInterval;
                _lastWrittenUtc = DateTime.MinValue;
            }

            public bool ShouldWriteFrame(DateTime nowUtc)
            {
                var last = _lastWrittenUtc;
                return last == DateTime.MinValue || (nowUtc - last) >= _writeInterval;
            }

            public void MarkFrameWritten(DateTime nowUtc)
            {
                _lastWrittenUtc = nowUtc;
            }
        }
    }
}
