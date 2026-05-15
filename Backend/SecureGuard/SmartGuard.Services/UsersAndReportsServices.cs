using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public class UsersService : BaseGetService<UserDto, ApplicationUser, BaseSearchObject>, IUsersService
    {
        public UsersService(SmartGuardContext context) : base(context)
        {
        }
    }

    public class ReportsService : BaseGetService<object, object, BaseSearchObject>, IReportsService
    {
        public ReportsService(SmartGuardContext context) : base(context)
        {
        }
    }
}
