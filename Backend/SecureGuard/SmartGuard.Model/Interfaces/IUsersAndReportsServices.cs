using SmartGuard.Model.SearchObjects;
using SmartGuard.Model.DTOs;

namespace SmartGuard.Model.Interfaces
{
    public interface IUsersService : IBaseGetService<UserDto, BaseSearchObject>
    {
    }

    public interface IReportsService : IBaseGetService<object, BaseSearchObject>
    {
    }
}
