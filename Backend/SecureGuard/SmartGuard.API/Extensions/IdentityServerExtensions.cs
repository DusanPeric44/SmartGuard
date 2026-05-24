using Duende.IdentityServer.Models;
using SmartGuard.Services.Database;

namespace SmartGuard.API.Extensions
{
    public static class IdentityServerExtensions
    {
        public static IServiceCollection AddIdentityServerConfiguration(this IServiceCollection services)
        {
            var secret = Clients.ToList()[0].ClientSecrets;
            services.AddIdentityServer(options =>
            {
                options.UserInteraction.LoginUrl = "/auth/login";
                options.UserInteraction.LoginReturnUrlParameter = "com.smart.guard://callback";
            });
            services.AddIdentityServerBuilder()
                    .AddAspNetIdentity<ApplicationUser>()
                    .AddInMemoryClients(Clients)
                    .AddInMemoryApiScopes(ApiScopes)
                    .AddInMemoryIdentityResources(IdentityResources)
                    .AddDeveloperSigningCredential();

            return services;
        }

        private static IEnumerable<IdentityResource> IdentityResources =>
        [
            new IdentityResources.OpenId(),
            new IdentityResources.Profile(),
        ];

        private static IEnumerable<ApiScope> ApiScopes =>
            [
                new ApiScope("smart-guard-api", "SmartGuard API")
            ];

        private static IEnumerable<Client> Clients =>
            [
                new Client
                {
                    ClientId = "flutter_app",
                    ClientName = "Flutter Mobile Client App",
                    AllowedGrantTypes = GrantTypes.Code,
                    RequirePkce = true,
                    RequireClientSecret = false,
                    RedirectUris = { "com.smart.guard://callback" },
                    PostLogoutRedirectUris = { "com.smart.guard://callback" },
                    AllowedScopes = { "openid", "profile", "email", "smart-guard-api" },
                    AllowOfflineAccess = true,
                }
            ];
    }
}
