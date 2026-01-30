using MediatR;
using Microsoft.Extensions.Logging;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Application.Commands;

public record CreateZakupCommand(CreateZakupRequest Request, Guid AdminId) : IRequest;

public class CreateZakupCommandHandler : IRequestHandler<CreateZakupCommand>
{
    private readonly AppDbContext _context;
    private readonly ILogger<CreateZakupCommandHandler> _logger;

    public CreateZakupCommandHandler(AppDbContext context, ILogger<CreateZakupCommandHandler> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task Handle(CreateZakupCommand command, CancellationToken cancellationToken)
    {
        var request = command.Request;
        var adminId = command.AdminId;

        _logger.LogInformation("Admin {AdminId} creating zakup: ProductId={ProductId}, Quantity={Quantity}, CostPrice={CostPrice}",
            adminId, request.ProductId, request.Quantity, request.CostPrice);

        try
        {
            // Validate admin
            var admin = await _context.Users
                .FirstOrDefaultAsync(u => u.Id == adminId && u.IsActive, cancellationToken)
                ?? throw new Exception($"Admin with ID {adminId} not found or inactive");

            var zakup = new Zakup
            {
                Id = Guid.NewGuid(),
                ProductId = request.ProductId,
                Quantity = request.Quantity,
                CostPrice = request.CostPrice,
                CreatedByAdminId = adminId
            };

            _context.Zakups.Add(zakup);
            await _context.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Zakup created successfully: ZakupId={ZakupId}", zakup.Id);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating zakup: {Message}", ex.Message);
            throw;
        }
    }
}
