using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartGuard.Notifications.Microservice.Migrations
{
    /// <inheritdoc />
    public partial class NotificationsSchema : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "notifications");

            migrationBuilder.RenameTable(
                name: "Notifications",
                newName: "Notifications",
                newSchema: "notifications");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameTable(
                name: "Notifications",
                schema: "notifications",
                newName: "Notifications");
        }
    }
}
