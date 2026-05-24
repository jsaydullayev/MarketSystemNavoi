-- Migration: Add Logs table for Serilog structured logging
-- Date: 2026-02-22
-- Description: Creates a centralized logging table with JSONB support for structured properties

-- Create Logs table
CREATE TABLE IF NOT EXISTS "Logs" (
    "Id" serial PRIMARY KEY,
    "Timestamp" timestamp with time zone NOT NULL DEFAULT (now() AT TIME ZONE 'UTC'),
    "Level" varchar(10) NOT NULL,
    "Message" text,
    "MessageTemplate" text,
    "Properties" jsonb,

    -- Context fields (optional, for faster querying)
    "UserName" varchar(100),
    "MarketId" integer,
    "UserId" integer,

    -- Additional metadata
    "Exception" text,
    "StackTrace" text,

    -- Foreign keys (optional, can be NULL for system logs)
    CONSTRAINT "FK_Logs_Users_UserId" FOREIGN KEY ("UserId") REFERENCES "Users"("Id") ON DELETE SET NULL,
    CONSTRAINT "FK_Logs_Markets_MarketId" FOREIGN KEY ("MarketId") REFERENCES "Markets"("Id") ON DELETE SET NULL
);

-- Create indexes for performance
-- Index on Timestamp (for time-based queries)
CREATE INDEX IF NOT EXISTS "IX_Logs_Timestamp" ON "Logs"("Timestamp" DESC);

-- Index on Level (for filtering by log level)
CREATE INDEX IF NOT EXISTS "IX_Logs_Level" ON "Logs"("Level");

-- Index on UserId (for user activity tracking)
CREATE INDEX IF NOT EXISTS "IX_Logs_UserId" ON "Logs"("UserId");

-- Index on MarketId (for multi-tenant filtering)
CREATE INDEX IF NOT EXISTS "IX_Logs_MarketId" ON "Logs"("MarketId");

-- Index on UserName (for user search)
CREATE INDEX IF NOT EXISTS "IX_Logs_UserName" ON "Logs"("UserName");

-- GIN index on Properties (for JSONB queries - e.g., searching by SaleId, ProductId, etc.)
CREATE INDEX IF NOT EXISTS "IX_Logs_Properties" ON "Logs" USING GIN ("Properties");

-- Composite index for common queries (logs by user and date)
CREATE INDEX IF NOT EXISTS "IX_Logs_UserId_Timestamp" ON "Logs"("UserId", "Timestamp" DESC);

-- Composite index for market-specific logs
CREATE INDEX IF NOT EXISTS "IX_Logs_MarketId_Timestamp" ON "Logs"("MarketId", "Timestamp" DESC);

-- Composite index for error logs (level filtering)
CREATE INDEX IF NOT EXISTS "IX_Logs_Level_Timestamp" ON "Logs"("Level", "Timestamp" DESC);

-- Add comments for documentation
COMMENT ON TABLE "Logs" IS 'Structured log entries from Serilog for application monitoring and audit trail';
COMMENT ON COLUMN "Logs"."Id" IS 'Unique identifier for each log entry';
COMMENT ON COLUMN "Logs"."Timestamp" IS 'UTC timestamp when the log entry was created';
COMMENT ON COLUMN "Logs"."Level" IS 'Log level: Verbose, Debug, Information, Warning, Error, Fatal';
COMMENT ON COLUMN "Logs"."Message" IS 'Formatted log message';
COMMENT ON COLUMN "Logs"."MessageTemplate" IS 'Original message template before formatting';
COMMENT ON COLUMN "Logs"."Properties" IS 'JSONB object containing structured properties (e.g., SaleId, Amount, etc.)';
COMMENT ON COLUMN "Logs"."UserName" IS 'Username who performed the action (denormalized for performance)';
COMMENT ON COLUMN "Logs"."MarketId" IS 'Market ID for multi-tenant filtering';
COMMENT ON COLUMN "Logs"."UserId" IS 'User ID who performed the action';
COMMENT ON COLUMN "Logs"."Exception" IS 'Exception message if an error occurred';
COMMENT ON COLUMN "Logs"."StackTrace" IS 'Stack trace if an error occurred';

-- Create a function for automatic log cleanup (optional, for maintenance)
-- Usage: SELECT cleanup_old_logs(days => 90);
CREATE OR REPLACE FUNCTION cleanup_old_logs(days integer DEFAULT 90)
RETURNS integer AS $$
DECLARE
    deleted_count integer;
BEGIN
    DELETE FROM "Logs"
    WHERE "Timestamp" < (now() AT TIME ZONE 'UTC' - (days || ' days')::interval);

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_old_logs(integer) IS 'Deletes log entries older than specified number of days. Returns count of deleted records.';

-- Log retention policy: 90 days (default)
-- Note: This is a manual function. For automatic cleanup, create a cron job or pg_cron extension.
