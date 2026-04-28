using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Identity.Web;
using Microsoft.OpenApi;
using SmartGuard.Model.Interfaces;
using SmartGuard.Services;
using SmartGuard.Services.Database;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

// 1. Database Configuration
builder.Services.AddDbContext<SmartGuardContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// 2. Identity Configuration
builder.Services.AddIdentity<IdentityUser, IdentityRole>()
    .AddEntityFrameworkStores<SmartGuardContext>()
    .AddDefaultTokenProviders();

// 3. Authentication (Microsoft Entra ID / Azure AD)
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

// 4. Dependency Injection (Scoped)
builder.Services.AddScoped<IDevicesService, DevicesService>();

builder.Services.AddControllers();

builder.Services.AddOpenApi();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(
    options =>
    {
        options.SwaggerDoc("v1", new OpenApiInfo
        {
            Version = "v1",
            Title = "SmartGuard API",
            Description = "API for managing devices and recordings in the SmartGuard application"
        });
    });

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();

    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();