using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Yamore.Services.Migrations
{
    /// <inheritdoc />
    public partial class EnsureNewsItemsImageUrlRemoved : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Some databases still had ImageUrl after the earlier remove migration (e.g. out-of-sync
            // history, failed drop, or restore). Idempotent: safe if the column is already gone.
            migrationBuilder.Sql(@"
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[NewsItems]') AND name = N'ImageUrl'
)
    ALTER TABLE [dbo].[NewsItems] DROP COLUMN [ImageUrl];
");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[NewsItems]') AND name = N'ImageUrl'
)
    ALTER TABLE [dbo].[NewsItems] ADD [ImageUrl] NVARCHAR(500) NULL;
");
        }
    }
}
