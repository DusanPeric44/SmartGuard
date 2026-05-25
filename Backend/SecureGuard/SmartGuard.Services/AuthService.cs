using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using SmartGuard.Model;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Services.Audit;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class AuthService : IAuthService
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<ApplicationRole> _roleManager;
        private readonly IConfiguration _configuration;
        private readonly SmartGuardContext _context;
        private readonly IMailingService _mailingService;
        private readonly ILogger<AuthService> _logger;

        public AuthService(
            UserManager<ApplicationUser> userManager,
            RoleManager<ApplicationRole> roleManager,
            IConfiguration configuration,
            SmartGuardContext context,
            IMailingService mailingService,
            ILogger<AuthService> logger)
        {
            _userManager = userManager;
            _roleManager = roleManager;
            _configuration = configuration;
            _context = context;
            _mailingService = mailingService;
            _logger = logger;
        }

        public async Task<AuthResponse> LoginAsync(LoginRequest request)
        {
            var email = request.Email?.Trim() ?? string.Empty;
            var user = await _userManager.FindByEmailAsync(email);
            if (user is ISoftDeletable softDeletable && softDeletable.IsDeleted)
            {
                _logger.LogAuditFailed(user.Id, "UserLoginFailed", $"User:{user.Id}", $"Email={email}; Reason=Deleted");
                throw new UnauthorizedAccessException("Invalid email or password");
            }
            if (user == null)
            {
                _logger.LogAuditFailed((string?)null, "UserLoginFailed", "Auth:Login", $"Email={email}; Reason=UserNotFound");
                throw new UnauthorizedAccessException("Invalid email or password");
            }
            if (!await _userManager.CheckPasswordAsync(user, request.Password))
            {
                _logger.LogAuditFailed(user.Id, "UserLoginFailed", $"User:{user.Id}", $"Email={email}; Reason=InvalidPassword");
                throw new UnauthorizedAccessException("Invalid email or password");
            }

            return await GenerateAuthResponseAsync(user);
        }

        public async Task<AuthResponse> RegisterAsync(RegisterRequest request)
        {
            var existingUser = await _userManager.FindByEmailAsync(request.Email);
            if (existingUser != null)
            {
                throw new UserException("User already exists");
            }

            var user = new ApplicationUser
            {
                Email = request.Email,
                UserName = request.Email,
                FirstName = request.FirstName,
                LastName = request.LastName,
                RegistrationKey = Guid.NewGuid().ToString()
            };

            var result = await _userManager.CreateAsync(user, request.Password);
            if (!result.Succeeded)
            {
                throw new UserException(string.Join(", ", result.Errors.Select(e => e.Description)));
            }

            // Assign default role
            await _userManager.AddToRoleAsync(user, "Viewer");

            _logger.LogAuditSuccess(user.Id, "UserRegistered", $"User:{user.Id}", $"Email={user.Email}; Role=Viewer");
            return await GenerateAuthResponseAsync(user);
        }

        public async Task<AuthResponse> RefreshTokenAsync(RefreshTokenRequest request)
        {
            var validatedToken = GetPrincipalFromExpiredToken(request.Token);
            if (validatedToken == null)
            {
                throw new UnauthorizedAccessException("Invalid token");
            }

            var expiryDateUnix = long.Parse(validatedToken.Claims.Single(x => x.Type == JwtRegisteredClaimNames.Exp).Value);
            var expiryDateTimeUtc = DateTimeOffset.FromUnixTimeSeconds(expiryDateUnix).UtcDateTime;

            if (expiryDateTimeUtc > DateTime.UtcNow)
            {
                throw new UserException("Token has not expired yet");
            }

            var jti = validatedToken.Claims.Single(x => x.Type == JwtRegisteredClaimNames.Jti).Value;
            var storedRefreshToken = await _context.RefreshTokens.SingleOrDefaultAsync(x => x.Token == request.RefreshToken);

            if (storedRefreshToken == null ||
                DateTime.UtcNow > storedRefreshToken.ExpiryDate ||
                storedRefreshToken.IsUsed ||
                storedRefreshToken.IsRevoked ||
                storedRefreshToken.JwtId != jti)
            {
                throw new UnauthorizedAccessException("Invalid refresh token");
            }

            storedRefreshToken.IsUsed = true;
            _context.RefreshTokens.Update(storedRefreshToken);
            await _context.SaveChangesAsync();

            var user = await _userManager.FindByEmailAsync(validatedToken.Claims.Single(x => x.Type == ClaimTypes.NameIdentifier).Value);
            if (user is ISoftDeletable softDeletable && softDeletable.IsDeleted)
            {
                throw new UnauthorizedAccessException("Invalid token");
            }
            return await GenerateAuthResponseAsync(user!);
        }

        public async Task<AuthResponse> ExternalProviderCallbackAsync(ExternalProviderCallbackRequest request)
        {
            var provider = request.Provider?.Trim() ?? string.Empty;
            var email = request.Email?.Trim() ?? string.Empty;

            if (string.IsNullOrWhiteSpace(provider))
            {
                throw new UserException("Provider is required");
            }

            if (string.IsNullOrWhiteSpace(email))
            {
                throw new UnauthorizedAccessException("Invalid external login");
            }

            var user = await _userManager.FindByEmailAsync(email);
            if (user is ISoftDeletable softDeletable && softDeletable.IsDeleted)
            {
                _logger.LogAuditFailed(user.Id, "UserExternalLoginFailed", $"User:{user.Id}", $"Email={email}; Provider={provider}; Reason=Deleted");
                throw new UnauthorizedAccessException("Invalid login");
            }

            if (user == null)
            {
                var firstName = request.FirstName?.Trim() ?? string.Empty;
                var lastName = request.LastName?.Trim() ?? string.Empty;

                user = new ApplicationUser
                {
                    Email = email,
                    UserName = email,
                    FirstName = firstName,
                    LastName = lastName,
                    RegistrationKey = Guid.NewGuid().ToString()
                };

                var result = await _userManager.CreateAsync(user);
                if (!result.Succeeded)
                {
                    _logger.LogAuditFailed((string?)null, "UserExternalLoginFailed", $"Auth:{provider}", $"Email={email}; Reason=IdentityCreateFailed");
                    throw new UserException(string.Join(", ", result.Errors.Select(e => e.Description)));
                }

                await _userManager.AddToRoleAsync(user, "Viewer");
                _logger.LogAuditSuccess(user.Id, "UserExternalRegistered", $"User:{user.Id}", $"Email={email}; Provider={provider}; Role=Viewer");
            }
            else if (string.IsNullOrWhiteSpace(user.RegistrationKey))
            {
                user.RegistrationKey = Guid.NewGuid().ToString();
                await _userManager.UpdateAsync(user);
            }

            _logger.LogAuditSuccess(user.Id, "UserExternalLoginSuccess", $"User:{user.Id}", $"Email={email}; Provider={provider}");
            return await GenerateAuthResponseAsync(user);
        }

        public async Task<AuthResponse> ExternalLoginAsync(ExternalLoginRequest request)
        {
            throw new NotImplementedException("External token login is not supported. Use the external provider callback flow.");
        }

        public async Task ForgotPasswordAsync(ForgotPasswordRequest request)
        {
            var user = await _userManager.FindByEmailAsync(request.Email);
            if (user == null) return; // Don't reveal that the user doesn't exist
            if (user is ISoftDeletable softDeletable && softDeletable.IsDeleted) return;

            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            
            var subject = "SmartGuard - Reset Password";
            var body = $"Your password reset token is: {token}. Please use this token to reset your password.";
            
            await _mailingService.SendEmailAsync(user.Email!, subject, body);
        }

        public async Task ResetPasswordAsync(ResetPasswordRequest request)
        {
            var user = await _userManager.FindByEmailAsync(request.Email);
            if (user == null || (user is ISoftDeletable softDeletable && softDeletable.IsDeleted))
                throw new UserException("User not found");

            var result = await _userManager.ResetPasswordAsync(user, request.Token, request.NewPassword);
            if (!result.Succeeded)
            {
                throw new UserException(string.Join(", ", result.Errors.Select(e => e.Description)));
            }
        }

        public async Task ChangePasswordAsync(string userId, ChangePasswordRequest request)
        {
            var user = await _userManager.FindByIdAsync(userId);
            if (user == null || (user is ISoftDeletable softDeletable && softDeletable.IsDeleted))
            {
                throw new UserException("User not found");
            }

            var currentPassword = request.CurrentPassword ?? string.Empty;
            var newPassword = request.NewPassword ?? string.Empty;

            var result = await _userManager.ChangePasswordAsync(user, currentPassword, newPassword);
            if (!result.Succeeded)
            {
                _logger.LogAuditFailed(user.Id, "UserChangePasswordFailed", $"User:{user.Id}", "Identity change password failed");
                throw new UserException(string.Join(", ", result.Errors.Select(e => e.Description)));
            }

            await _userManager.UpdateSecurityStampAsync(user);
            _logger.LogAuditSuccess(user.Id, "UserPasswordChanged", $"User:{user.Id}", "Password changed");
        }

        public async Task<UserDto> GetCurrentUserAsync(string email)
        {
            var user = await _userManager.FindByEmailAsync(email) 
                ?? throw new UserException("User not found");

            var roles = await _userManager.GetRolesAsync(user);

            return new UserDto
            {
                Id = user.Id,
                Email = user.Email!,
                FirstName = user.FirstName,
                LastName = user.LastName,
                RegistrationKey = user.RegistrationKey,
                Role = roles.FirstOrDefault() ?? string.Empty
            };
        }

        public async Task<string> GetRegistrationKeyAsync(string email)
        {
            var user = await _userManager.FindByEmailAsync(email)
                ?? throw new UserException("User not found");

            return user.RegistrationKey;
        }

        private async Task<AuthResponse> GenerateAuthResponseAsync(ApplicationUser user)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.ASCII.GetBytes(_configuration["Jwt:Secret"] ?? "DefaultSecretKeyForSmartGuardAPI1234567890");
            
            var roles = await _userManager.GetRolesAsync(user);
            var claims = new List<Claim>
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Email!),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                new Claim(JwtRegisteredClaimNames.Email, user.Email!),
                new Claim(ClaimTypes.NameIdentifier, user.Email!),
                new Claim("UserId", user.Id),
                new Claim("FirstName", user.FirstName),
                new Claim("LastName", user.LastName)
            };

            foreach (var role in roles)
            {
                claims.Add(new Claim(ClaimTypes.Role, role));
            }

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = DateTime.UtcNow.AddMinutes(double.Parse(_configuration["Jwt:ExpiryInMinutes"] ?? "60")),
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature),
                Issuer = _configuration["Jwt:Issuer"],
                Audience = _configuration["Jwt:Audience"]
            };

            var token = tokenHandler.CreateToken(tokenDescriptor);
            var refreshToken = new RefreshToken
            {
                JwtId = token.Id,
                UserId = user.Id,
                CreationDate = DateTime.UtcNow,
                ExpiryDate = DateTime.UtcNow.AddMonths(1),
                Token = Guid.NewGuid().ToString() + "-" + Guid.NewGuid().ToString()
            };

            await _context.RefreshTokens.AddAsync(refreshToken);
            await _context.SaveChangesAsync();

            return new AuthResponse
            {
                Token = tokenHandler.WriteToken(token),
                RefreshToken = refreshToken.Token,
                Expiration = tokenDescriptor.Expires.Value,
                User = new UserDto
                {
                    Id = user.Id,
                    Email = user.Email!,
                    FirstName = user.FirstName,
                    LastName = user.LastName,
                    RegistrationKey = user.RegistrationKey,
                    Role = roles.FirstOrDefault() ?? string.Empty
                }
            };
        }

        private ClaimsPrincipal? GetPrincipalFromExpiredToken(string token)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.ASCII.GetBytes(_configuration["Jwt:Secret"] ?? "DefaultSecretKeyForSmartGuardAPI1234567890");

            var tokenValidationParameters = new TokenValidationParameters
            {
                ValidateAudience = false,
                ValidateIssuer = false,
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ValidateLifetime = false // We want to get claims from expired token
            };

            try
            {
                var principal = tokenHandler.ValidateToken(token, tokenValidationParameters, out var validatedToken);
                if (!IsJwtWithValidSecurityAlgorithm(validatedToken))
                {
                    return null;
                }

                return principal;
            }
            catch
            {
                return null;
            }
        }

        private bool IsJwtWithValidSecurityAlgorithm(SecurityToken validatedToken)
        {
            return (validatedToken is JwtSecurityToken jwtSecurityToken) &&
                   jwtSecurityToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.InvariantCultureIgnoreCase);
        }
    }
}
