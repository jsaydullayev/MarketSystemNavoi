using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

public record ProfitSummaryDto(
    [property: JsonPropertyName("todayProfit")] decimal TodayProfit,
    [property: JsonPropertyName("weekProfit")] decimal WeekProfit,
    [property: JsonPropertyName("monthProfit")] decimal MonthProfit,
    [property: JsonPropertyName("totalProfit")] decimal TotalProfit
);
