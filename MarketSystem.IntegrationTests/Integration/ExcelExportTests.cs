using ClosedXML.Excel;
using MarketSystem.Application.Services;
using FluentAssertions;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Guards the Excel export pipeline (ExcelService.GenerateExcel).
///
/// The Products / Customers / Sales controllers build their rows as anonymous
/// types, cast the sequence to <c>object</c>, then call GenerateExcel through a
/// <c>(dynamic)</c> argument. These tests reproduce that exact call shape and
/// assert the workbook actually contains the headers and data — a regression
/// here silently ships blank spreadsheets.
/// </summary>
public class ExcelExportTests
{
    private static XLWorkbook OpenWorkbook(byte[] bytes)
        => new XLWorkbook(new MemoryStream(bytes));

    [Fact]
    public void GenerateExcel_WithTypedAnonymousSequence_WritesHeadersAndRows()
    {
        var rows = new[]
        {
            new { Id = "1", Name = "Olma", Price = 1500 },
            new { Id = "2", Name = "Non", Price = 3000 },
        };

        var bytes = new ExcelService().GenerateExcel(rows, "Test");

        using var wb = OpenWorkbook(bytes);
        var ws = wb.Worksheet(1);
        ws.Cell(1, 1).GetString().Should().Be("Id");
        ws.Cell(1, 2).GetString().Should().Be("Name");
        ws.Cell(1, 3).GetString().Should().Be("Price");
        ws.Cell(2, 2).GetString().Should().Be("Olma");
        ws.Cell(3, 2).GetString().Should().Be("Non");
    }

    [Fact]
    public void GenerateExcel_WithObjectCastSequenceViaDynamic_StillWritesColumns()
    {
        // Exactly the controller pattern: a LINQ Select projection to an
        // anonymous type, .Cast<object>()-ed, held in an `object` variable,
        // then passed through (dynamic). This is the shape Products /
        // Customers / Sales exports use.
        var source = new List<string> { "Olma", "Non" };
        object exportData = source
            .Select((name, i) => new { Id = (i + 1).ToString(), Name = name })
            .Cast<object>();

        // A dynamic argument makes the call's result dynamic too — pin it back
        // to byte[] so the assertions below run against ClosedXML, not dynamic.
        byte[] bytes = new ExcelService().GenerateExcel((dynamic)exportData, "Test");

        using var wb = OpenWorkbook(bytes);
        var ws = wb.Worksheet(1);

        // The header row MUST carry the anonymous-type member names. If the
        // generic resolved to <object> the sheet would be completely empty.
        ws.Cell(1, 1).GetString().Should().Be("Id");
        ws.Cell(1, 2).GetString().Should().Be("Name");
        ws.Cell(2, 1).GetString().Should().Be("1");
        ws.Cell(3, 2).GetString().Should().Be("Non");
        ws.LastColumnUsed()!.ColumnNumber().Should().Be(2);
    }
}
