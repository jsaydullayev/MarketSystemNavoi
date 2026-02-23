-- Update owner user password with correct BCrypt hash
-- Password: owner123
UPDATE "Users"
SET "PasswordHash" = '$2a$11$HmfGrWOoeIywsDlqSGfjPuXbIFpMJz6J/pWbrE/7O6bOyeSXY7ASS'
WHERE "Username" = 'owner';
