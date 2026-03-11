using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Yamore.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddYachtImages : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "YachtImages",
                columns: table => new
                {
                    YachtImageId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    YachtId = table.Column<int>(type: "int", nullable: false),
                    ImageData = table.Column<byte[]>(type: "varbinary(max)", nullable: false),
                    ContentType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    FileName = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    IsThumbnail = table.Column<bool>(type: "bit", nullable: false),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    DateAdded = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "(getdate())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_YachtImages", x => x.YachtImageId);
                    table.ForeignKey(
                        name: "FK_YachtImages_Yachts_YachtId",
                        column: x => x.YachtId,
                        principalTable: "Yachts",
                        principalColumn: "YachtId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_YachtImages_YachtId",
                table: "YachtImages",
                column: "YachtId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "YachtImages");
        }
    }
}
