using MediatR;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Application.Commands;

public record CreateSaleCommand(CreateSaleRequest Request) : IRequest<SaleResponse>;

public class CreateSaleCommandHandler : IRequestHandler<CreateSaleCommand, SaleResponse>
{
    private readonly AppDbContext _context;

    public CreateSaleCommandHandler(AppDbContext context)
    {
        _context = context;
    }

    public async Task<SaleResponse> Handle(CreateSaleCommand command, CancellationToken cancellationToken)
    {
        var request = command.Request;

        // Validate seller exists and belongs to branch
        var seller = await _context.Users
            .FirstOrDefaultAsync(u => u.Id == request.SellerId && u.BranchId == request.BranchId && u.IsActive, cancellationToken)
            ?? throw new Exception("Seller not found or inactive");

        // Validate customer if provided
        if (request.CustomerId.HasValue)
        {
            var customerExists = await _context.Customers.AnyAsync(c => c.Id == request.CustomerId.Value && !c.IsDeleted, cancellationToken);
            if (!customerExists)
                throw new Exception("Customer not found");
        }

        var sale = new Sale
        {
            Id = Guid.NewGuid(),
            BranchId = request.BranchId,
            SellerId = request.SellerId,
            CustomerId = request.CustomerId,
            Status = SaleStatus.Draft,
            TotalAmount = 0,
            PaidAmount = 0
        };

        _context.Sales.Add(sale);
        await _context.SaveChangesAsync(cancellationToken);

        return new SaleResponse(sale.Id, sale.BranchId, sale.SellerId, sale.Status, 0, 0, 0, [], []);
    }
}
