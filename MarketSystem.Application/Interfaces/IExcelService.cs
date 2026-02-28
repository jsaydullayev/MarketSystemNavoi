using System.Collections.Generic;

namespace MarketSystem.Application.Interfaces
{
    public interface IExcelService
    {
        byte[] GenerateExcel<T>(IEnumerable<T> data, string sheetName = "Sheet1");
    }
}
