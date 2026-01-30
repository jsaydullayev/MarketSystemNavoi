using MediatR;
using Microsoft.EntityFrameworkCore;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.Application.Queries;

public record GetSaleByIdQuery(Guid SaleId) : IRequest<SaleResponse?>;

public class GetSaleByIdQueryHandler : IRequestHandler<GetSaleByIdQuery, SaleResponse?>
{
    private readonly AppDbContext _context;

    public GetSaleByIdQueryHandler(AppDbContext context)
    {
        _context = context; 
    }

    public async Task<SaleResponse?> Handle(GetSaleByIdQuery query, CancellationToken cancellationToken)
    {
        var sale = await _context.Sales
            .Include(s => s.SaleItems).ThenInclude(si => si.Product)
            .Include(s => s.Payments)
            .FirstOrDefaultAsync(s => s.Id == query.SaleId, cancellationToken);

        if (sale == null) return null;

        var items = sale.SaleItems.Select(si => new SaleItemResponse(
            si.Id,
            si.ProductId,
            si.Product.Name,
            si.Quantity,
            si.CostPrice,
            si.SalePrice,
            si.Profit,
            si.Comment
        )).ToList();

        var payments = sale.Payments.Select(p => new PaymentResponse(
            p.Id,
            p.PaymentType,
            p.Amount,
            p.CreatedAt
        )).ToList();

        return new SaleResponse(
            sale.Id,
            sale.BranchId,
            sale.SellerId,
            sale.Status,
            sale.TotalAmount,
            sale.PaidAmount,
            sale.TotalAmount - sale.PaidAmount,
            items,
            payments
        );
    }
}

public record GetDraftSalesByBranchQuery(Guid BranchId) : IRequest<IEnumerable<DraftSaleResponse>>;

public class GetDraftSalesByBranchQueryHandler : IRequestHandler<GetDraftSalesByBranchQuery, IEnumerable<DraftSaleResponse>>
{
    private readonly AppDbContext _context;

    public GetDraftSalesByBranchQueryHandler(AppDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<DraftSaleResponse>> Handle(GetDraftSalesByBranchQuery query, CancellationToken cancellationToken)
    {
        return await _context.Sales
            .Include(s => s.SaleItems).ThenInclude(si => si.Product)
            .Where(s => s.BranchId == query.BranchId && s.Status == SaleStatus.Draft)
            .Select(s => new DraftSaleResponse(
                s.Id,
                s.SellerId,
                s.Seller.FullName,
                s.TotalAmount,
                s.SaleItems.Select(si => new DraftSaleItemResponse(
                    si.ProductId,
                    si.Product.Name,
                    si.Quantity
                )).ToList()
            ))
            .ToListAsync(cancellationToken);
    }
}

public record DraftSaleResponse(Guid Id, Guid SellerId, string SellerName, decimal TotalAmount, List<DraftSaleItemResponse> Items);
public record DraftSaleItemResponse(Guid ProductId, string ProductName, decimal Quantity);
