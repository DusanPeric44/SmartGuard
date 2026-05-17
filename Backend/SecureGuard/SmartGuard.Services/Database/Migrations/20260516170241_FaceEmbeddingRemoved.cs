using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartGuard.Services.Database.Migrations
{
    /// <inheritdoc />
    public partial class FaceEmbeddingRemoved : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "FaceEmbedding",
                table: "KnownPersons");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<byte[]>(
                name: "FaceEmbedding",
                table: "KnownPersons",
                type: "varbinary(max)",
                nullable: false,
                defaultValue: new byte[0]);
        }
    }
}
