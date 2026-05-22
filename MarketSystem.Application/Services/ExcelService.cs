using ClosedXML.Excel;
using MarketSystem.Application.Interfaces;
using System;
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
                    SetCellValue(worksheet.Cell(i + 2, j + 1), value);
                }
            }

            // Auto-adjust column width
            worksheet.Columns().AdjustToContents();

            using var stream = new MemoryStream();
            workbook.SaveAs(stream);
            return stream.ToArray();
        }

        /// <summary>
        /// Write <paramref name="value"/> into <paramref name="cell"/> with the
        /// correct Excel data type so numeric columns stay numeric (SUM /
        /// formulas / chart plotting work) and dates render as dates rather
        /// than serial numbers. Previously every value was forced to
        /// <c>ToString()</c>, which turned every column into text and broke
        /// Excel's number-aware features for the customer.
        /// </summary>
        private static void SetCellValue(IXLCell cell, object? value)
        {
            switch (value)
            {
                case null:
                    cell.Value = string.Empty;
                    break;
                case bool b:
                    cell.Value = b;
                    break;
                case DateTime dt:
                    cell.Value = dt;
                    // Plain date-time format; Excel still recognises the value
                    // as a real date so PivotTables / sorting / filters work.
                    cell.Style.DateFormat.Format = "yyyy-MM-dd HH:mm";
                    break;
                case decimal d:
                    cell.Value = d;
                    break;
                case double dbl:
                    cell.Value = dbl;
                    break;
                case float f:
                    cell.Value = (double)f;
                    break;
                case int n:
                    cell.Value = n;
                    break;
                case long l:
                    cell.Value = l;
                    break;
                case short s:
                    cell.Value = (int)s;
                    break;
                case Enum e:
                    // Show the readable name, not the underlying int.
                    cell.Value = e.ToString();
                    break;
                default:
                    // Strings, Guids, anything we don't specifically handle.
                    cell.Value = value.ToString() ?? string.Empty;
                    break;
            }
        }
    }
}
