-- Yangi Owner user qo'shish
-- Username: owner
-- Password: owner123 (BCrypt bilan hashlangan)

INSERT INTO "Users" ("Id", "Username", "PasswordHash", "FullName", "Role", "Language", "MarketId", "CreatedAt", "IsActive", "IsDeleted")
VALUES (
    '11111111-1111-1111-1111-111111111112',
    'owner',
    '$2a$11$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj9SjKE.F4.G',  -- "owner123"
    'Owner User',
    3,  -- Role: Owner
    2,  -- Language: Uzbek
    NULL,  -- Owner uchun MarketId NULL bo'lishi mumkin
    NOW(),
    true,
    false
)
ON CONFLICT ("Id") DO NOTHING;
