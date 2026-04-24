using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Yamore.Services.Migrations
{
    /// <inheritdoc />
    public partial class RemoveNewsItemImageUrl : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ImageUrl",
                table: "NewsItems");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ImageUrl",
                table: "NewsItems",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);
        }
    }
}
