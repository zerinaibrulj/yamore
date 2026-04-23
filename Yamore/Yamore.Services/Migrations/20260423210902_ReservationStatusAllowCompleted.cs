using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Yamore.Services.Migrations
{
    /// <inheritdoc />
    public partial class ReservationStatusAllowCompleted : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Hosted DBs often have a manual CHECK (e.g. CK__Reservati__Statu__*) on [Reservations].[Status]
            // that only allows Pending/Confirmed/Cancelled. "Completed" was added in app code later, so
            // marking a trip complete fails until the constraint includes that value.
            migrationBuilder.Sql(@"
-- Resolve CHECK names via sys.objects (reliable) and use each constraint’s parent
-- table from sys.check_constraints.parent_object_id for ALTER … DROP.
DECLARE @tblId int = OBJECT_ID(N'[dbo].[Reservations]', N'U');
IF @tblId IS NULL
    THROW 50000, N'Migration: table [dbo].[Reservations] not found. Update the script if your table is in another schema.', 1;

DECLARE @cname sysname, @poid int, @drop nvarchar(600);
WHILE 1 = 1
BEGIN
    -- Reset so a SELECT with 0 rows does not keep the previous @cname.
    SET @cname = NULL; SET @poid = NULL;

    SELECT TOP (1) @cname = o.name, @poid = cc.parent_object_id
    FROM sys.check_constraints cc
    JOIN sys.objects o ON o.object_id = cc.object_id
    WHERE o.type = N'C' AND cc.parent_object_id = @tblId
      AND (
        (cc.definition IS NOT NULL AND cc.definition LIKE N'%[[]Status]%')
        OR o.name LIKE N'CK__Reservati%Statu%'
      );

    IF @cname IS NULL BREAK;

    SET @drop = N'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(@poid)) + N'.' + QUOTENAME(OBJECT_NAME(@poid))
        + N' DROP CONSTRAINT ' + QUOTENAME(@cname) + N';'
    EXEC sys.sp_executesql @drop;
END

IF NOT EXISTS (
    SELECT 1
    FROM sys.objects o
    WHERE o.name = N'CK_Reservations_Status' AND o.type = N'C' AND o.parent_object_id = @tblId
)
BEGIN
    ALTER TABLE [dbo].[Reservations] ADD CONSTRAINT [CK_Reservations_Status]
    CHECK ([Status] IN (N'Pending', N'Confirmed', N'Cancelled', N'Completed'));
END
");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
IF EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_Reservations_Status'
      AND parent_object_id = OBJECT_ID(N'[dbo].[Reservations]'))
    ALTER TABLE [dbo].[Reservations] DROP CONSTRAINT [CK_Reservations_Status];

-- Restores a typical pre-Completed CHECK. Fails if any row has Status = 'Completed'.
IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints c
    WHERE c.parent_object_id = OBJECT_ID(N'[dbo].[Reservations]')
      AND c.definition IS NOT NULL
      AND c.definition LIKE N'%[[]Status]%')
ALTER TABLE [dbo].[Reservations] ADD CONSTRAINT [CK_Reservations_Status_Legacy]
    CHECK ([Status] IN (N'Pending', N'Confirmed', N'Cancelled'));
");
        }
    }
}
