using Microsoft.EntityFrameworkCore;
using SmartGuard.Model;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class UserPushTokensService : IUserPushTokensService
    {
        private readonly SmartGuardContext _context;
        private readonly IUserContext _userContext;

        public UserPushTokensService(SmartGuardContext context, IUserContext userContext)
        {
            _context = context;
            _userContext = userContext;
        }

        public async Task UpsertAsync(UserPushTokenUpsertRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Token))
            {
                throw new UserException("Token is required");
            }

            var email = _userContext.Email;
            if (string.IsNullOrWhiteSpace(email))
            {
                throw new UserException("Unauthorized");
            }

            var user = await _context.Users.SingleOrDefaultAsync(u => u.Email == email)
                ?? throw new UserException("User not found");

            var existing = await _context.UserPushTokens.SingleOrDefaultAsync(x => x.Token == request.Token);
            if (existing == null)
            {
                await _context.UserPushTokens.AddAsync(new UserPushToken
                {
                    UserId = user.Id,
                    Token = request.Token,
                    Platform = request.Platform,
                    UpdatedAt = DateTime.UtcNow
                });
            }
            else
            {
                existing.UserId = user.Id;
                existing.Platform = request.Platform;
                existing.UpdatedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
        }
    }
}
