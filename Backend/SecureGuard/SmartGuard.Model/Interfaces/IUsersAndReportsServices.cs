using SmartGuard.Model.SearchObjects;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Requests;

namespace SmartGuard.Model.Interfaces
{
    public interface IUsersService : IBaseGetService<UserDto, UsersSearchObject>
    {
        Task<InviteUserResult> InviteAsync(InviteUserRequest request);
        Task<UserDto> UpdateAsync(string id, UpdateUserRequest request);
        Task DeleteAsync(string id);
    }

    public interface IReportsService : IBaseGetService<object, BaseSearchObject>
    {
    }
}
