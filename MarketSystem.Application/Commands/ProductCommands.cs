using MediatR;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Application.Commands;

public record CreateProductCommand(CreateProductRequest Request) : IRequest;

public class CreateProductCommandHandler : IRequestHandler<CreateProductCommand>
{
    private readonly AppDbContext _context;

    public CreateProductCommandHandler(AppDbContext context)
    {
        _context = context;
    }

    public async Task Handle(CreateProductCommand command, CancellationToken cancellationToken)
    {
        var product = new Product
        {
            Id = Guid.NewGuid(),
            Name = command.Request.Name,
            IsTemporary = false
        };

        _context.Products.Add(product);
        await _context.SaveChangesAsync(cancellationToken);
    }
}

public record CreateBranchProductCommand(CreateBranchProductRequest Request) : IRequest;

public class CreateBranchProductCommandHandler : IRequestHandler<CreateBranchProductCommand>
{
    private readonly AppDbContext _context;

    public CreateBranchProductCommandHandler(AppDbContext context)
    {
        _context = context;
    }

    public async Task Handle(CreateBranchProductCommand command, CancellationToken cancellationToken)
    {
        var request = command.Request;

        // Validate branch and product exist
        var branchExists = await _context.Branches.AnyAsync(b => b.Id == request.BranchId, cancellationToken);
        if (!branchExists)
            throw new Exception("Branch not found");

        var productExists = await _context.Products.AnyAsync(p => p.Id == request.ProductId, cancellationToken);
        if (!productExists)
            throw new Exception("Product not found");

        var branchProduct = new BranchProduct
        {
            Id = Guid.NewGuid(),
            BranchId = request.BranchId,
            ProductId = request.ProductId,
            CostPrice = request.CostPrice,
            SalePrice = request.SalePrice,
            MinSalePrice = request.MinSalePrice,
            Quantity = request.Quantity,
            MinThreshold = request.MinThreshold
        };

        _context.BranchProducts.Add(branchProduct);
        await _context.SaveChangesAsync(cancellationToken);
    }
}
