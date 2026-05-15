using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Mapster;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SmartGuard.Model;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class UserDeviceAccessService : BaseCRUDService<Model.DTOs.UserDeviceAccess, Database.UserDeviceAccess, UserDeviceAccessSearchObject, UserDeviceAccessInsertRequest, UserDeviceAccessUpdateRequest>, IUserDeviceAccessService
    {
        private readonly UserManager<ApplicationUser> _userManager;

        public UserDeviceAccessService(SmartGuardContext context, UserManager<ApplicationUser> userManager) : base(context)
        {
            _userManager = userManager;
        }

        public override async Task<Model.DTOs.UserDeviceAccess> InsertAsync(UserDeviceAccessInsertRequest insert)
        {
            if (insert == null)
            {
                throw new UserException("Request is required");
            }

            if (insert.DeviceId < 1)
            {
                throw new UserException("DeviceId is required");
            }

            var userIds = (insert.UserIds ?? new List<string>())
                .Select(x => (x ?? string.Empty).Trim())
                .Where(x => x.Length > 0)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            if (userIds.Count == 0)
            {
                throw new UserException("At least one UserId is required");
            }

            var deviceExists = await _context.Devices.AnyAsync(x => x.Id == insert.DeviceId);
            if (!deviceExists)
            {
                throw new KeyNotFoundException("Device not found");
            }

            var users = await _context.Users
                .Where(x => userIds.Contains(x.Id) && !x.IsDeleted)
                .ToListAsync();

            var foundUserIds = users.Select(x => x.Id).ToHashSet(StringComparer.OrdinalIgnoreCase);
            if (foundUserIds.Count != userIds.Count)
            {
                throw new KeyNotFoundException("One or more users were not found");
            }

            var existingAccess = await _context.UserDeviceAccesses
                .Where(x => x.DeviceId == insert.DeviceId && userIds.Contains(x.UserId))
                .ToListAsync();

            var accessByUserId = existingAccess.ToDictionary(x => x.UserId, StringComparer.OrdinalIgnoreCase);

            foreach (var user in users)
            {
                var roles = await _userManager.GetRolesAsync(user);
                if (roles == null || roles.Count == 0)
                {
                    throw new UserException("User role is missing");
                }

                var hasHomeOwner = roles.Any(r => string.Equals(r, "HomeOwner", StringComparison.OrdinalIgnoreCase));
                var hasAdmin = roles.Any(r => string.Equals(r, "Admin", StringComparison.OrdinalIgnoreCase));
                var hasViewer = roles.Any(r => string.Equals(r, "Viewer", StringComparison.OrdinalIgnoreCase));

                if (!hasHomeOwner && !hasAdmin && !hasViewer)
                {
                    throw new UserException("User role is not supported for device access");
                }

                var canDownload = hasHomeOwner || hasAdmin;
                var canStream = true;

                if (accessByUserId.TryGetValue(user.Id, out var row))
                {
                    row.CanStream = canStream;
                    row.CanDownload = canDownload;
                }
                else
                {
                    row = new Database.UserDeviceAccess
                    {
                        UserId = user.Id,
                        DeviceId = insert.DeviceId,
                        CanStream = canStream,
                        CanDownload = canDownload
                    };

                    _context.UserDeviceAccesses.Add(row);
                    accessByUserId[user.Id] = row;
                }
            }

            await _context.SaveChangesAsync();

            var representativeUserId = userIds[0];
            var representativeRow = accessByUserId[representativeUserId];
            return representativeRow.Adapt<Model.DTOs.UserDeviceAccess>();
        }
    }
}
