using SmartGuard.Model.Interfaces;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class UsersController : BaseGetController<object, BaseSearchObject>
    {
        public UsersController(IUsersService service) : base(service)
        {
        }
    }
}
