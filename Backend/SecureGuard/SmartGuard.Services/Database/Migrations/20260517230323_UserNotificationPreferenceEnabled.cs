using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartGuard.Services.Database.Migrations
{
    /// <inheritdoc />
    public partial class UserNotificationPreferenceEnabled : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ReceiveEmail",
                table: "UserNotificationPreferences");

            migrationBuilder.DropColumn(
                name: "ReceivePush",
                table: "UserNotificationPreferences");

            migrationBuilder.AddColumn<bool>(
                name: "Enabled",
                table: "UserNotificationPreferences",
                type: "bit",
                nullable: false,
                defaultValue: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Enabled",
                table: "UserNotificationPreferences");

            migrationBuilder.AddColumn<bool>(
                name: "ReceiveEmail",
                table: "UserNotificationPreferences",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "ReceivePush",
                table: "UserNotificationPreferences",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }
    }
}
