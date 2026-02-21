using System.Text;

namespace MarketSystem.API.Helpers;

public static class CsvHelper
{
    public static string GenerateCsv<T>(IEnumerable<T> data, string[] headers, Func<T, string[]> selector)
    {
        var sb = new StringBuilder();

        // Header row
        sb.AppendLine(string.Join(",", headers.Select(EscapeCsvField)));

        // Data rows
        foreach (var item in data)
        {
            var fields = selector(item);
            sb.AppendLine(string.Join(",", fields.Select(EscapeCsvField)));
        }

        return sb.ToString();
    }

    private static string EscapeCsvField(string field)
    {
        if (string.IsNullOrEmpty(field))
            return "";

        // Agar field ichida verga, newline yoki double quote bo'lsa, qavusga olish kerak
        if (field.Contains(",") || field.Contains("\"") || field.Contains("\n") || field.Contains("\r"))
        {
            return $"\"{field.Replace("\"", "\"\"")}\"";
        }

        return field;
    }

    public static byte[] GenerateExcelCsv(string csvContent)
    {
        // UTF-8 BOM qo'shamiz (Excel uchun)
        var preamble = Encoding.UTF8.GetPreamble();
        var content = Encoding.UTF8.GetBytes(csvContent);
        var result = new byte[preamble.Length + content.Length];
        Buffer.BlockCopy(preamble, 0, result, 0, preamble.Length);
        Buffer.BlockCopy(content, 0, result, preamble.Length, content.Length);
        return result;
    }
}
