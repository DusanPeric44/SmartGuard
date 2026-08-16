using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartGuard.Services.Database.Migrations
{
    /// <inheritdoc />
    [DbContext(typeof(SmartGuardContext))]
    [Migration("20260816180000_HashDeviceApiKey")]
    public partial class HashDeviceApiKey : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "ApiKey",
                table: "Devices",
                newName: "ApiKeyHash");

            // Existing plaintext keys cannot be turned into valid hashes; devices must re-register
            // (the ESP32 registration flow issues a fresh key and stores only its hash from now on).
            migrationBuilder.Sql("UPDATE Devices SET ApiKeyHash = ''");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "ApiKeyHash",
                table: "Devices",
                newName: "ApiKey");
        }
    }
}
