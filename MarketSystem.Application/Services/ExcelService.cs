using ClosedXML.Excel;
using MarketSystem.Application.Interfaces;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace MarketSystem.Application.Services
{
    public class ExcelService : IExcelService
    {
        public byte[] GenerateExcel<T>(IEnumerable<T> data, string sheetName = "Sheet1")
        {
            using var workbook = new XLWorkbook();
            var worksheet = workbook.Worksheets.Add(sheetName);

            var properties = typeof(T).GetProperties();
            
            // Generate headers
            for (int i = 0; i < properties.Length; i++)
            {
                worksheet.Cell(1, i + 1).Value = properties[i].Name;
                worksheet.Cell(1, i + 1).Style.Font.Bold = true;
            }

            // Fill data
            var dataList = data.ToList();
            for (int i = 0; i < dataList.Count; i++)
            {
                for (int j = 0; j < properties.Length; j++)
                {
                    var value = properties[j].GetValue(dataList[i]);
                    worksheet.Cell(i + 2, j + 1).Value = value?.ToString() ?? string.Empty;
                }
            }

            // Auto-adjust column width
            worksheet.Columns().AdjustToContents();

            using var stream = new MemoryStream();
            workbook.SaveAs(stream);
            return stream.ToArray();
        }
    }
}
