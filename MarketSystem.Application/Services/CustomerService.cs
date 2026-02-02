using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;

namespace MarketSystem.Application.Services;

public class CustomerService : ICustomerService
{
    private readonly IUnitOfWork _unitOfWork;

    public CustomerService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<CustomerDto?> GetCustomerByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var customer = await _unitOfWork.Customers.GetByIdAsync(id, cancellationToken);
        if (customer is null)
            return null;

        return await MapToDtoAsync(customer, cancellationToken);
    }

    public async Task<CustomerDto?> GetCustomerByPhoneAsync(string phone, CancellationToken cancellationToken = default)
    {
        var customers = await _unitOfWork.Customers.FindAsync(
            c => c.Phone == phone,
            cancellationToken);

        var customer = customers.FirstOrDefault();
        if (customer is null)
            return null;

        return await MapToDtoAsync(customer, cancellationToken);
    }

    public async Task<IEnumerable<CustomerDto>> GetAllCustomersAsync(CancellationToken cancellationToken = default)
    {
        var customers = await _unitOfWork.Customers.GetAllAsync(cancellationToken);
        var result = new List<CustomerDto>();

        foreach (var customer in customers)
        {
            result.Add(await MapToDtoAsync(customer, cancellationToken));
        }

        return result;
    }

    public async Task<CustomerDto> CreateCustomerAsync(CreateCustomerDto request, CancellationToken cancellationToken = default)
    {
        // Check if phone already exists
        if (await _unitOfWork.Customers.AnyAsync(c => c.Phone == request.Phone, cancellationToken))
            throw new InvalidOperationException($"Customer with phone '{request.Phone}' already exists");

        var customer = new Customer
        {
            Id = Guid.NewGuid(),
            Phone = request.Phone,
            FullName = request.FullName,
            IsDeleted = false
        };

        await _unitOfWork.Customers.AddAsync(customer, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return await MapToDtoAsync(customer, cancellationToken);
    }

    public async Task<CustomerDto?> UpdateCustomerAsync(UpdateCustomerDto request, CancellationToken cancellationToken = default)
    {
        var customer = await _unitOfWork.Customers.GetByIdAsync(request.Id, cancellationToken);
        if (customer is null)
            return null;

        // Check if phone is being changed and if new phone already exists
        if (customer.Phone != request.Phone &&
            await _unitOfWork.Customers.AnyAsync(c => c.Phone == request.Phone && c.Id != request.Id, cancellationToken))
            throw new InvalidOperationException($"Customer with phone '{request.Phone}' already exists");

        customer.Phone = request.Phone;
        customer.FullName = request.FullName;

        _unitOfWork.Customers.Update(customer);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return await MapToDtoAsync(customer, cancellationToken);
    }

    public async Task<bool> DeleteCustomerAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var customer = await _unitOfWork.Customers.GetByIdAsync(id, cancellationToken);
        if (customer is null)
            return false;

        _unitOfWork.Customers.Delete(customer);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> SoftDeleteCustomerAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var customer = await _unitOfWork.Customers.GetByIdAsync(id, cancellationToken);
        if (customer is null)
            return false;

        customer.IsDeleted = true;
        _unitOfWork.Customers.Update(customer);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return true;
    }

    private async Task<CustomerDto> MapToDtoAsync(Customer customer, CancellationToken cancellationToken)
    {
        // Calculate total debt for this customer
        var debts = await _unitOfWork.Debts.FindAsync(
            d => d.CustomerId == customer.Id && d.Status == DebtStatus.Open,
            cancellationToken);

        var totalDebt = debts.Sum(d => d.RemainingDebt);

        return new CustomerDto(
            customer.Id,
            customer.Phone,
            customer.FullName,
            totalDebt
        );
    }
}
