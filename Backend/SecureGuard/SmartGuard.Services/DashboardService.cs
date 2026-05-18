using System;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Options;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Options;

namespace SmartGuard.Services
{
    public class DashboardService : IDashboardService
    {
        private const string DesktopCacheKey = "dashboard:desktop:v1";
        private const string MobileCacheKey = "dashboard:mobile:v1";
        private static readonly TimeSpan CacheTtl = TimeSpan.FromSeconds(30);

        private readonly Database.SmartGuardContext _context;
        private readonly IDistributedCache _cache;
        private readonly FileStorageOptions _fileStorageOptions;

        public DashboardService(Database.SmartGuardContext context, IDistributedCache cache, IOptions<FileStorageOptions> fileStorageOptions)
        {
            _context = context;
            _cache = cache;
            _fileStorageOptions = fileStorageOptions.Value;
        }

        public Task<DashboardDesktop> GetDesktopAsync()
        {
            return GetOrCreateAsync(DesktopCacheKey, BuildDesktopAsync);
        }

        public Task<DashboardMobile> GetMobileAsync()
        {
            return GetOrCreateAsync(MobileCacheKey, BuildMobileAsync);
        }

        private async Task<DashboardDesktop> BuildDesktopAsync()
        {
            var connectedStatusIds = await _context.DeviceStatuses
                .AsNoTracking()
                .Where(x => x.Name == "Online" || x.Name == "Recording")
                .Select(x => x.Id)
                .ToListAsync();

            var pendingAlertStatusId = await _context.AlertStatuses
                .AsNoTracking()
                .Where(x => x.Name == "Pending")
                .Select(x => x.Id)
                .SingleAsync();

            var devicesCount = await _context.Devices.AsNoTracking().CountAsync();
            var connectedDevicesCount = await _context.Devices.AsNoTracking().CountAsync(d => connectedStatusIds.Contains(d.StatusId));
            var recordingsCount = await _context.Recordings.AsNoTracking().CountAsync(r => !r.IsDeleted);
            var pendingAlarmsCount = await _context.Alerts.AsNoTracking().CountAsync(a => a.StatusId == pendingAlertStatusId);
            var activeUsersCount = await _context.Users.AsNoTracking().CountAsync(u => !u.IsDeleted);

            var usedVideosBytes = await _context.Recordings
                .AsNoTracking()
                .Where(r => !r.IsDeleted)
                .SumAsync(r => (long?)r.Size) ?? 0;

            var usedImagesBytes = GetDirectorySizeSafe(Path.Combine(_fileStorageOptions.UploadsRootPath, _fileStorageOptions.ImagesSubfolder));
            var usedReportsBytes = GetDirectorySizeSafe(Path.Combine(_fileStorageOptions.UploadsRootPath, _fileStorageOptions.ReportsSubfolder));

            var lastAuditLogs = await _context.AuditLogs
                .AsNoTracking()
                .OrderByDescending(x => x.Timestamp)
                .Take(5)
                .Select(x => new SmartGuard.Model.DTOs.AuditLog
                {
                    Id = x.Id,
                    UserId = x.UserId ?? string.Empty,
                    Action = x.Action,
                    Resource = x.Resource,
                    Status = x.Status,
                    Timestamp = x.Timestamp,
                    Details = x.Details
                })
                .ToListAsync();

            return new DashboardDesktop
            {
                DevicesCount = devicesCount,
                ConnectedDevicesCount = connectedDevicesCount,
                RecordingsCount = recordingsCount,
                PendingAlarmsCount = pendingAlarmsCount,
                ActiveUsersCount = activeUsersCount,
                UsedVideosBytes = usedVideosBytes,
                UsedImagesBytes = usedImagesBytes,
                UsedReportsBytes = usedReportsBytes,
                LastAuditLogs = lastAuditLogs
            };
        }

        private async Task<DashboardMobile> BuildMobileAsync()
        {
            var pendingAlertStatusId = await _context.AlertStatuses
                .AsNoTracking()
                .Where(x => x.Name == "Pending")
                .Select(x => x.Id)
                .SingleAsync();

            var devicesCount = await _context.Devices.AsNoTracking().CountAsync();
            var pendingAlarmsCount = await _context.Alerts.AsNoTracking().CountAsync(a => a.StatusId == pendingAlertStatusId);

            var mobileDevices = await _context.Devices
                .AsNoTracking()
                .OrderBy(x => x.Name)
                .Select(x => new DashboardDeviceListItem
                {
                    Id = x.Id,
                    Name = x.Name
                })
                .ToListAsync();

            return new DashboardMobile
            {
                DevicesCount = devicesCount,
                PendingAlarmsCount = pendingAlarmsCount,
                Devices = mobileDevices
            };
        }

        private async Task<T> GetOrCreateAsync<T>(string cacheKey, Func<Task<T>> factory)
        {
            var cached = await _cache.GetAsync(cacheKey);
            if (cached != null && cached.Length > 0)
            {
                var dto = JsonSerializer.Deserialize<T>(cached);
                if (dto != null)
                {
                    return dto;
                }
            }

            var dtoResult = await factory();
            await _cache.SetAsync(
                cacheKey,
                JsonSerializer.SerializeToUtf8Bytes(dtoResult),
                new DistributedCacheEntryOptions
                {
                    AbsoluteExpirationRelativeToNow = CacheTtl
                });

            return dtoResult;
        }

        private static long GetDirectorySizeSafe(string? directoryPath)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(directoryPath) || !Directory.Exists(directoryPath))
                {
                    return 0;
                }

                long sum = 0;
                foreach (var file in Directory.EnumerateFiles(directoryPath, "*", SearchOption.AllDirectories))
                {
                    try
                    {
                        sum += new FileInfo(file).Length;
                    }
                    catch
                    {
                    }
                }

                return sum;
            }
            catch
            {
                return 0;
            }
        }
    }
}
