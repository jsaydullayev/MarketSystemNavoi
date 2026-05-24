-- Remove old partial migration record
DELETE FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260203112625_AddSoftDeleteAndAuditLog';
