namespace MarketSystem.Domain.Enums;

public enum Role
{
    SuperAdmin,  // Barcha marketlarni boshqaradi
    Owner,       // Faqat o'z marketini boshqaradi
    Admin,       // Faqat o'z marketida ma'lum huquqlar
    Seller       // Faqat o'z marketida sotuv
}
