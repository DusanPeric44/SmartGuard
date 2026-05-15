using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using SmartGuard.Model;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class AuthService : IAuthService
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly IConfiguration _configuration;
        private readonly SmartGuardContext _context;
        private readonly IMailingService _mailingService;

        public AuthService(
            UserManager<ApplicationUser> userManager,
            RoleManager<IdentityRole> roleManager,
            IConfiguration configuration,
            SmartGuardContext context,
            IMailingService mailingService)
        {
            _userManager = userManager;
            _roleManager = roleManager;
            _configuration = configuration;
            _context = context;
            _mailingService = mailingService;
        }

        public async Task<AuthResponse> LoginAsync(LoginRequest request)
        {
            var user = await _userManager.FindByEmailAsync(request.Email);
            if (user == null || !await _userManager.CheckPasswordAsync(user, request.Password))
            {
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
            return await GenerateAuthResponseAsync(user!);
        }

        public async Task<AuthResponse> ExternalLoginAsync(ExternalLoginRequest request)
        {
            // TODO: Implement external token validation (Google/Microsoft)
            // For now, this is a placeholder. In a real app, you'd use GoogleJsonWebSignature.ValidateAsync or similar.
            throw new NotImplementedException("External login validation not yet implemented");
        }

        public async Task ForgotPasswordAsync(ForgotPasswordRequest request)
        {
            var user = await _userManager.FindByEmailAsync(request.Email);
            if (user == null) return; // Don't reveal that the user doesn't exist

            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            
            var subject = "SmartGuard - Reset Password";
            var body = $"Your password reset token is: {token}. Please use this token to reset your password.";
            
            await _mailingService.SendEmailAsync(user.Email!, subject, body);
        }

        public async Task ResetPasswordAsync(ResetPasswordRequest request)
        {
            var user = await _userManager.FindByEmailAsync(request.Email);
            if (user == null) throw new UserException("User not found");

            var result = await _userManager.ResetPasswordAsync(user, request.Token, request.NewPassword);
            if (!result.Succeeded)
            {
                throw new UserException(string.Join(", ", result.Errors.Select(e => e.Description)));
            }
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
