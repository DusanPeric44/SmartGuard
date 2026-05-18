using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartGuard.Services.Database.Migrations
{
    /// <inheritdoc />
    public partial class AddAuditLogFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Resource",
                table: "AuditLogs",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Status",
                table: "AuditLogs",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "Success");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Resource",
                table: "AuditLogs");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "AuditLogs");
        }
    }
}
