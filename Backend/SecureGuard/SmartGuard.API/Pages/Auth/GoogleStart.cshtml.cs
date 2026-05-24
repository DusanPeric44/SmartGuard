using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace SmartGuard.API.Pages.Auth
{
    [AllowAnonymous]
    public class GoogleStartModel : PageModel
    {
        public IActionResult OnGet()
        {
            return Challenge(new AuthenticationProperties
            {
                RedirectUri = "/auth/google"
            }, "Google");
        }
    }
}

