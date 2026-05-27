using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartGuard.Services.Database.Migrations
{
    /// <inheritdoc />
    public partial class RemoveFaceIdAddScore : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "FaceId",
                table: "FaceDetectionEvents");

            migrationBuilder.AddColumn<double>(
                name: "Score",
                table: "FaceDetectionEvents",
                type: "float",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Score",
                table: "FaceDetectionEvents");

            migrationBuilder.AddColumn<int>(
                name: "FaceId",
                table: "FaceDetectionEvents",
                type: "int",
                nullable: true);
        }
    }
}
