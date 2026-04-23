using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Yamore.Services.Migrations
{
    /// <inheritdoc />
    public partial class ReservationLifecycleAudit : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // May drop a legacy non-unique index on UserId; we recreate it at the end of Up if missing.
            migrationBuilder.Sql(@"
                IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Reservations_UserId' AND object_id = OBJECT_ID(N'[Reservations]'))
                    DROP INDEX [IX_Reservations_UserId] ON [Reservations];
            ");

            migrationBuilder.AddColumn<string>(
                name: "StatusChangeReason",
                table: "Reservations",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "StatusChangedAt",
                table: "Reservations",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "StatusChangedByUserId",
                table: "Reservations",
                type: "int",
                nullable: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Reservations_UserId' AND object_id = OBJECT_ID(N'[Reservations]'))
                    CREATE NONCLUSTERED INDEX [IX_Reservations_UserId] ON [Reservations] ([UserId]);
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Reservations_UserId' AND object_id = OBJECT_ID(N'[Reservations]'))
                    DROP INDEX [IX_Reservations_UserId] ON [Reservations];
            ");

            migrationBuilder.DropColumn(
                name: "StatusChangeReason",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "StatusChangedAt",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "StatusChangedByUserId",
                table: "Reservations");
        }
    }
}
