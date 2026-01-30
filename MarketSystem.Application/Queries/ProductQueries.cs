using MediatR;
using Microsoft.EntityFrameworkCore;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.Application.Queries;

public record GetBranchProductsQuery(Guid BranchId) : IRequest<IEnumerable<BranchProductResponse>>;

public class GetBranchProductsQueryHandler : IRequestHandler<GetBranchProductsQuery, IEnumerable<BranchProductResponse>>
{
    private readonly AppDbContext _context;

    public GetBranchProductsQueryHandler(AppDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<BranchProductResponse>> Handle(GetBranchProductsQuery query, CancellationToken cancellationToken)
    {
        return await _context.BranchProducts
            .Include(bp => bp.Product)
            .Where(bp => bp.BranchId == query.BranchId)
            .Select(bp => new BranchProductResponse(
                bp.Id,
                bp.ProductId,
                bp.Product.Name,
                bp.CostPrice,
                bp.SalePrice,
                bp.MinSalePrice,
                bp.Quantity,
                bp.MinThreshold,
                bp.Quantity <= bp.MinThreshold
            ))
            .ToListAsync(cancellationToken);
    }
}
