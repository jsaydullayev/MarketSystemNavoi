namespace MarketSystem.Domain.Entities;

/// <summary>
/// Market/Tenant - alohida biznes egasi
/// </summary>
public class Market
{
    public int Id { get; set; }  // Primary Key - int (auto-increment)
    public string Name { get; set; } = string.Empty;
    public string? Subdomain { get; set; }  // market1.example.com
    public string? Description { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime? ExpiresAt { get; set; }  // Subscription uchun
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public ICollection<User> Users { get; set; } = new List<User>();
    public ICollection<Product> Products { get; set; } = new List<Product>();
    public ICollection<Customer> Customers { get; set; } = new List<Customer>();
    public ICollection<Sale> Sales { get; set; } = new List<Sale>();
    public ICollection<Zakup> Zakups { get; set; } = new List<Zakup>();
    public ICollection<Debt> Debts { get; set; } = new List<Debt>();
    public ICollection<CashRegister> CashRegisters { get; set; } = new List<CashRegister>();
}
