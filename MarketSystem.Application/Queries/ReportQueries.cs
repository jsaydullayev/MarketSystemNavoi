using MarketSystem.Infrastructure.Data;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Application.Queries;

public record GetSalesReportQuery(Guid BranchId, DateTime StartDate, DateTime EndDate) : IRequest<SalesReportResponse>;

public class GetSalesReportQueryHandler : IRequestHandler<GetSalesReportQuery, SalesReportResponse>
{
    private readonly AppDbContext _context;

    public GetSalesReportQueryHandler(AppDbContext context)
    {
        _context = context;
    }

    public async Task<SalesReportResponse> Handle(GetSalesReportQuery query, CancellationToken cancellationToken)
    {
        var sales = await _context.Sales
            .Include(s => s.SaleItems)
            .Where(s => s.BranchId == query.BranchId
                && s.CreatedAt >= query.StartDate
                && s.CreatedAt <= query.EndDate
                && s.Status != MarketSystem.Domain.Enums.SaleStatus.Cancelled)
            .ToListAsync(cancellationToken);

        var totalSales = sales.Sum(s => s.TotalAmount);
        var profit = sales.Sum(s => s.SaleItems.Sum(si => si.Profit));

        var zakups = await _context.Zakups
            .Where(z => z.BranchId == query.BranchId
                && z.CreatedAt >= query.StartDate
                && z.CreatedAt <= query.EndDate)
            .ToListAsync(cancellationToken);

        var zakupTotal = zakups.Sum(z => z.Quantity * z.CostPrice);
        var netProfit = profit; // Can be adjusted for expenses

        return new SalesReportResponse(
            totalSales,
            zakupTotal,
            profit,
            netProfit
        );
    }
}

public record SalesReportResponse(decimal TotalSales, decimal ZakupTotal, decimal Profit, decimal NetProfit);
