using SmartGuard.Model.DTOs;
using SmartGuard.Model.Requests;

namespace SmartGuard.Model.Interfaces
{
    public interface IAuthService
    {
        Task<AuthResponse> LoginAsync(LoginRequest request);
        Task<AuthResponse> RegisterAsync(RegisterRequest request);
        Task<AuthResponse> RefreshTokenAsync(RefreshTokenRequest request);
        Task<AuthResponse> ExternalProviderCallbackAsync(ExternalProviderCallbackRequest request);
        Task ForgotPasswordAsync(ForgotPasswordRequest request);
        Task ResetPasswordAsync(ResetPasswordRequest request);
        Task ChangePasswordAsync(string userId, ChangePasswordRequest request);
        Task<UserDto> GetCurrentUserAsync(string email);
        Task<string> GetRegistrationKeyAsync(string email);
    }
}
