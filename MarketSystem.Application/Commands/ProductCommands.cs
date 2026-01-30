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
