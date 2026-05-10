using SmartGuard.Model.DTOs;
using SmartGuard.Model.Requests;

namespace SmartGuard.Model.Interfaces
{
    public interface IAuthService
    {
        Task<AuthResponse> LoginAsync(LoginRequest request);
        Task<AuthResponse> RegisterAsync(RegisterRequest request);
        Task<AuthResponse> RefreshTokenAsync(RefreshTokenRequest request);
        Task<AuthResponse> ExternalLoginAsync(ExternalLoginRequest request);
        Task ForgotPasswordAsync(ForgotPasswordRequest request);
        Task ResetPasswordAsync(ResetPasswordRequest request);
        Task<UserDto> GetCurrentUserAsync(string email);
        Task<string> GetRegistrationKeyAsync(string email);
    }
}
