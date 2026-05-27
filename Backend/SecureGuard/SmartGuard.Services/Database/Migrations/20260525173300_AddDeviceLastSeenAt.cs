using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartGuard.Services.Database.Migrations
{
    /// <inheritdoc />
    public partial class AddDeviceLastSeenAt : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "LastSeenAt",
                table: "Devices",
                type: "datetime2",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LastSeenAt",
                table: "Devices");
        }
    }
}
