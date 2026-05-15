using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartGuard.Services.Database.Migrations
{
    /// <inheritdoc />
    public partial class RemovedIPAddressDevice : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IPAddress",
                table: "Devices");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "IPAddress",
                table: "Devices",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");
        }
    }
}
