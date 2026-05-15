using SmartGuard.Model.Requests;

namespace SmartGuard.Model.Interfaces
{
    public interface IUserPushTokensService
    {
        Task UpsertAsync(UserPushTokenUpsertRequest request);
    }
}
