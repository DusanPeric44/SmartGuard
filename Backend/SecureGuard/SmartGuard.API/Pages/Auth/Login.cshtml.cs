using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace SmartGuard.API.Pages.Auth
{
    [AllowAnonymous]
    public class LoginModel : PageModel
    {
    }
}

