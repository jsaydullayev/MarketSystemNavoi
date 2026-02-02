using MarketSystem.Application.DTOs;

namespace MarketSystem.Domain.Interfaces;

public interface ICustomerService
{
    Task<CustomerDto?> GetCustomerByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<CustomerDto?> GetCustomerByPhoneAsync(string phone, CancellationToken cancellationToken = default);
    Task<IEnumerable<CustomerDto>> GetAllCustomersAsync(CancellationToken cancellationToken = default);
    Task<CustomerDto> CreateCustomerAsync(CreateCustomerDto request, CancellationToken cancellationToken = default);
    Task<CustomerDto?> UpdateCustomerAsync(UpdateCustomerDto request, CancellationToken cancellationToken = default);
    Task<bool> DeleteCustomerAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> SoftDeleteCustomerAsync(Guid id, CancellationToken cancellationToken = default);
}
