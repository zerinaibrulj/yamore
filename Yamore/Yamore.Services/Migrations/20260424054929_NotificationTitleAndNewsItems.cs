using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Yamore.Services.Migrations
{
    /// <inheritdoc />
    public partial class NotificationTitleAndNewsItems : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "Message",
                table: "Notifications",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(255)",
                oldMaxLength: 255);

            migrationBuilder.AddColumn<string>(
                name: "Title",
                table: "Notifications",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateTable(
                name: "NewsItems",
                columns: table => new
                {
                    NewsId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Title = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Text = table.Column<string>(type: "nvarchar(max)", maxLength: 8000, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NewsItems", x => x.NewsId);
                });

            migrationBuilder.Sql(@"
UPDATE [dbo].[Notifications] SET [Title] = N'Yamore' WHERE [Title] = N'' OR [Title] IS NULL;
");

            migrationBuilder.Sql(@"
IF NOT EXISTS (SELECT 1 FROM [dbo].[NewsItems])
INSERT INTO [dbo].[NewsItems] ([Title], [Text], [CreatedAt])
VALUES (
    N'Welcome to Yamore',
    N'Browse available yachts, check routes and weather, and book your next trip. This section lists platform news and updates (obavijesti).',
    GETUTCDATE()
);
");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "NewsItems");

            migrationBuilder.DropColumn(
                name: "Title",
                table: "Notifications");

            migrationBuilder.AlterColumn<string>(
                name: "Message",
                table: "Notifications",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(1000)",
                oldMaxLength: 1000);
        }
    }
}
