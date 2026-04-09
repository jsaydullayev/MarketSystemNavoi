using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddCreatedAtToProducts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                DO $$
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1 FROM information_schema.columns
                        WHERE table_name = 'Products' AND column_name = 'DeletedAt'
                    ) THEN
                        ALTER TABLE ""Products"" ADD ""DeletedAt"" timestamp with time zone;
                    END IF;
                END $$;

                DO $$
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1 FROM information_schema.columns
                        WHERE table_name = 'Products' AND column_name = 'UpdatedAt'
                    ) THEN
                        ALTER TABLE ""Products"" ADD ""UpdatedAt"" timestamp with time zone NOT NULL DEFAULT NOW();
                    END IF;
                END $$;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                DO $$
                BEGIN
                    IF EXISTS (
                        SELECT 1 FROM information_schema.columns
                        WHERE table_name = 'Products' AND column_name = 'DeletedAt'
                    ) THEN
                        ALTER TABLE ""Products"" DROP COLUMN ""DeletedAt"";
                    END IF;
                END $$;

                DO $$
                BEGIN
                    IF EXISTS (
                        SELECT 1 FROM information_schema.columns
                        WHERE table_name = 'Products' AND column_name = 'UpdatedAt'
                    ) THEN
                        ALTER TABLE ""Products"" DROP COLUMN ""UpdatedAt"";
                    END IF;
                END $$;
            ");
        }
    }
}
