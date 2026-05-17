using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using SmartGuard.Model.Interfaces;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class MediaDbMigrationService
    {
        private readonly SmartGuardContext _context;
        private readonly IFileStorageService _fileStorage;

        public MediaDbMigrationService(SmartGuardContext context, IFileStorageService fileStorage)
        {
            _context = context;
            _fileStorage = fileStorage;
        }

        public async Task<(int MigratedFaceDetectionEvents, int MigratedKnownPersons)> MigrateAsync(CancellationToken cancellationToken = default)
        {
            var migratedEvents = await MigrateFaceDetectionEventsAsync(cancellationToken);
            var migratedPersons = await MigrateKnownPersonsAsync(cancellationToken);
            return (migratedEvents, migratedPersons);
        }

        private async Task<int> MigrateFaceDetectionEventsAsync(CancellationToken cancellationToken)
        {
            var migrated = 0;

            var entities = await _context.FaceDetectionEvents
                .Where(x => x.Image != null && x.Image != string.Empty && !x.Image.StartsWith("/uploads/", StringComparison.OrdinalIgnoreCase))
                .ToListAsync(cancellationToken);

            foreach (var entity in entities)
            {
                var base64 = ExtractBase64(entity.Image);
                if (base64 == null) continue;

                if (!TryDecodeBase64(base64, out var bytes)) continue;

                var url = await _fileStorage.SaveImageAsync(bytes, ".jpg");
                entity.Image = url;
                migrated += 1;
            }

            if (migrated > 0)
            {
                await _context.SaveChangesAsync(cancellationToken);
            }

            return migrated;
        }

        private async Task<int> MigrateKnownPersonsAsync(CancellationToken cancellationToken)
        {
            var migrated = 0;

            var entities = await _context.KnownPersons
                .Where(x => x.Picture != null && x.Picture != string.Empty && !x.Picture.StartsWith("/uploads/", StringComparison.OrdinalIgnoreCase))
                .ToListAsync(cancellationToken);

            foreach (var entity in entities)
            {
                var base64 = ExtractBase64(entity.Picture);
                if (base64 == null) continue;

                if (!TryDecodeBase64(base64, out var bytes)) continue;

                var url = await _fileStorage.SaveImageAsync(bytes, ".jpg");
                entity.Picture = url;
                migrated += 1;
            }

            if (migrated > 0)
            {
                await _context.SaveChangesAsync(cancellationToken);
            }

            return migrated;
        }

        private static string? ExtractBase64(string value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return null;
            }

            var trimmed = value.Trim();
            var commaIdx = trimmed.IndexOf(',');
            if (commaIdx >= 0 && trimmed.StartsWith("data:", StringComparison.OrdinalIgnoreCase))
            {
                return trimmed[(commaIdx + 1)..];
            }

            return trimmed;
        }

        private static bool TryDecodeBase64(string value, out byte[] bytes)
        {
            try
            {
                bytes = Convert.FromBase64String(value);
                return bytes.Length > 0;
            }
            catch
            {
                bytes = Array.Empty<byte>();
                return false;
            }
        }
    }
}

