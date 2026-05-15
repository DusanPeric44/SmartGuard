using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

namespace SmartGuard.API.Controllers
{
    public class UsersController : BaseGetController<UserDto, BaseSearchObject>
    {
        public UsersController(IUsersService service) : base(service)
        {
        }
    }
}
