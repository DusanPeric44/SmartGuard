using System.Security.Cryptography;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Logging;
using SmartGuard.Model;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Audit;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class UsersService : BaseGetService<UserDto, ApplicationUser, UsersSearchObject>, IUsersService
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly INotificationPublisher _notificationPublisher;
        private readonly ILogger<UsersService> _logger;

        public UsersService(
            SmartGuardContext context,
            UserManager<ApplicationUser> userManager,
            RoleManager<IdentityRole> roleManager,
            INotificationPublisher notificationPublisher,
            ILogger<UsersService> logger) : base(context)
        {
            _userManager = userManager;
            _roleManager = roleManager;
            _notificationPublisher = notificationPublisher;
            _logger = logger;
        }

        protected override IQueryable<ApplicationUser> AddFilter(IQueryable<ApplicationUser> query, UsersSearchObject search = null)
        {
            if (!string.IsNullOrWhiteSpace(search?.Term))
            {
                var term = search.Term.Trim();
                query = query.Where(x =>
                    x.Email.Contains(term) ||
                    x.FirstName.Contains(term) ||
                    x.LastName.Contains(term));
            }

            return query;
        }

        public async Task<InviteUserResult> InviteAsync(InviteUserRequest request)
        {
            var email = request.Email?.Trim() ?? string.Empty;
            var role = request.Role?.Trim() ?? string.Empty;

            if (string.IsNullOrWhiteSpace(email))
            {
                throw new UserException("Email is required");
            }

            if (string.IsNullOrWhiteSpace(role))
            {
                throw new UserException("Role is required");
            }

            if (!await _roleManager.RoleExistsAsync(role))
            {
                throw new UserException("Role does not exist");
            }

            var existingUser = await _userManager.FindByEmailAsync(email);
            if (existingUser != null)
            {
                throw new UserException("User already exists");
            }

            var temporaryPassword = GeneratePassword();

            var user = new ApplicationUser
            {
                Email = email,
                UserName = email,
                EmailConfirmed = true,
                RegistrationKey = Guid.NewGuid().ToString()
            };

            var createResult = await _userManager.CreateAsync(user, temporaryPassword);
            if (!createResult.Succeeded)
            {
                throw new UserException(string.Join(", ", createResult.Errors.Select(e => e.Description)));
            }

            var addRoleResult = await _userManager.AddToRoleAsync(user, role);
            if (!addRoleResult.Succeeded)
            {
                await _userManager.DeleteAsync(user);
                throw new UserException(string.Join(", ", addRoleResult.Errors.Select(e => e.Description)));
            }

            try
            {
                await _notificationPublisher.SendInviteEmailAsync(email, role, temporaryPassword);
            }
            catch
            {
                await _userManager.DeleteAsync(user);
                throw;
            }

            _logger.LogAuditSuccess("UserInvited", $"User:{user.Id}", $"Email={email}; Role={role}");
            return new InviteUserResult
            {
                UserId = user.Id,
                Email = email,
                Role = role,
                TemporaryPassword = temporaryPassword
            };
        }

        public async Task<UserDto> UpdateAsync(string id, UpdateUserRequest request)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null || user.IsDeleted)
            {
                throw new KeyNotFoundException("User not found");
            }

            var firstName = request.FirstName?.Trim() ?? string.Empty;
            var lastName = request.LastName?.Trim() ?? string.Empty;
            var role = request.Role?.Trim() ?? string.Empty;

            if (string.IsNullOrWhiteSpace(firstName))
            {
                throw new UserException("FirstName is required");
            }

            if (string.IsNullOrWhiteSpace(lastName))
            {
                throw new UserException("LastName is required");
            }

            if (string.IsNullOrWhiteSpace(role))
            {
                throw new UserException("Role is required");
            }

            if (!await _roleManager.RoleExistsAsync(role))
            {
                throw new UserException("Role does not exist");
            }

            user.FirstName = firstName;
            user.LastName = lastName;

            var updateResult = await _userManager.UpdateAsync(user);
            if (!updateResult.Succeeded)
            {
                throw new UserException(string.Join(", ", updateResult.Errors.Select(e => e.Description)));
            }

            var currentRoles = await _userManager.GetRolesAsync(user);
            if (currentRoles.Count != 1 || !string.Equals(currentRoles[0], role, StringComparison.OrdinalIgnoreCase))
            {
                if (currentRoles.Count > 0)
                {
                    var removeRolesResult = await _userManager.RemoveFromRolesAsync(user, currentRoles);
                    if (!removeRolesResult.Succeeded)
                    {
                        throw new UserException(string.Join(", ", removeRolesResult.Errors.Select(e => e.Description)));
                    }
                }

                var addRoleResult = await _userManager.AddToRoleAsync(user, role);
                if (!addRoleResult.Succeeded)
                {
                    throw new UserException(string.Join(", ", addRoleResult.Errors.Select(e => e.Description)));
                }
            }

            var roles = await _userManager.GetRolesAsync(user);
            var result = new UserDto
            {
                Id = user.Id,
                Email = user.Email!,
                FirstName = user.FirstName,
                LastName = user.LastName,
                RegistrationKey = user.RegistrationKey,
                Role = roles.FirstOrDefault() ?? string.Empty
            };
            _logger.LogAuditSuccess("UserUpdated", $"User:{id}", $"FirstName={firstName}; LastName={lastName}; Role={result.Role}");
            return result;
        }

        public async Task DeleteAsync(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null || user.IsDeleted)
            {
                throw new KeyNotFoundException("User not found");
            }

            user.IsDeleted = true;

            var updateResult = await _userManager.UpdateAsync(user);
            if (!updateResult.Succeeded)
            {
                throw new UserException(string.Join(", ", updateResult.Errors.Select(e => e.Description)));
            }

            await _userManager.SetLockoutEnabledAsync(user, true);
            await _userManager.SetLockoutEndDateAsync(user, DateTimeOffset.MaxValue);
            await _userManager.UpdateSecurityStampAsync(user);
        }

        private static string GeneratePassword(int length = 12)
        {
            const string upper = "ABCDEFGHJKLMNPQRSTUVWXYZ";
            const string lower = "abcdefghijkmnopqrstuvwxyz";
            const string digits = "23456789";
            const string symbols = "!@#$%^&*_-+";

            if (length < 6) length = 6;

            Span<char> chars = stackalloc char[length];
            chars[0] = upper[RandomNumberGenerator.GetInt32(upper.Length)];
            chars[1] = lower[RandomNumberGenerator.GetInt32(lower.Length)];
            chars[2] = digits[RandomNumberGenerator.GetInt32(digits.Length)];
            chars[3] = symbols[RandomNumberGenerator.GetInt32(symbols.Length)];

            var all = upper + lower + digits + symbols;
            for (var i = 4; i < length; i++)
            {
                chars[i] = all[RandomNumberGenerator.GetInt32(all.Length)];
            }

            for (var i = chars.Length - 1; i > 0; i--)
            {
                var j = RandomNumberGenerator.GetInt32(i + 1);
                (chars[i], chars[j]) = (chars[j], chars[i]);
            }

            return new string(chars);
        }
    }
}
