namespace MarketSystem.Domain.Enums;

public enum PaymentType
{
    Cash,
    Terminal,
    Transfer,
    Click,
    // Credit applied from a customer's outstanding refund balance.
    // Tracked as a positive Payment so the credit is consumed exactly once
    // (see CustomerService.GetAvailableCreditAsync).
    Credit
}
