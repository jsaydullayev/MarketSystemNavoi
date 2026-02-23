SELECT
    c."FullName" as customer_name,
    c."Phone" as customer_phone,
    COUNT(d."Id") as debt_count,
    COALESCE(SUM(d."RemainingDebt"), 0) as total_debt
FROM "Customers" c
LEFT JOIN "Debts" d ON d."CustomerId" = c."Id" AND d."Status" = 0
WHERE c."Id" = '11111111-1111-1111-1111-111111111111'
GROUP BY c."Id", c."FullName", c."Phone";
