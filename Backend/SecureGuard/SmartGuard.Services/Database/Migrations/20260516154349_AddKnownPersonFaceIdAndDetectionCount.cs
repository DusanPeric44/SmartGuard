using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartGuard.Services.Database.Migrations
{
    /// <inheritdoc />
    public partial class AddKnownPersonFaceIdAndDetectionCount : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_KnownPersons_AspNetUsers_OwnerId",
                table: "KnownPersons");

            migrationBuilder.DropIndex(
                name: "IX_KnownPersons_OwnerId",
                table: "KnownPersons");

            migrationBuilder.DropColumn(
                name: "OwnerId",
                table: "KnownPersons");

            migrationBuilder.AddColumn<int>(
                name: "DetectionCount",
                table: "KnownPersons",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "FaceId",
                table: "KnownPersons",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_KnownPersons_FaceId",
                table: "KnownPersons",
                column: "FaceId",
                unique: true,
                filter: "[FaceId] IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DetectionCount",
                table: "KnownPersons");

            migrationBuilder.DropIndex(
                name: "IX_KnownPersons_FaceId",
                table: "KnownPersons");

            migrationBuilder.DropColumn(
                name: "FaceId",
                table: "KnownPersons");

            migrationBuilder.AddColumn<string>(
                name: "OwnerId",
                table: "KnownPersons",
                type: "nvarchar(450)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateIndex(
                name: "IX_KnownPersons_OwnerId",
                table: "KnownPersons",
                column: "OwnerId");

            migrationBuilder.AddForeignKey(
                name: "FK_KnownPersons_AspNetUsers_OwnerId",
                table: "KnownPersons",
                column: "OwnerId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
