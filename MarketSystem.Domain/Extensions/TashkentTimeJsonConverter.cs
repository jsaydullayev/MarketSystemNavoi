using System.Text.Json;
using System.Text.Json.Serialization;

namespace MarketSystem.Domain.Extensions
{
    /// <summary>
    /// JSON Converter that converts DateTime to GMT+5 (Tashkent Time) when serializing
    /// Database stores UTC, but API returns GMT+5 to clients
    /// </summary>
    public class TashkentTimeJsonConverter : JsonConverter<DateTime>
    {
        private static readonly TimeZoneInfo TashkentTimeZone = TimeZoneInfo.FindSystemTimeZoneById("Central Asia Standard Time");

        public override DateTime Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            // When reading from JSON, assume it's already in Tashkent time or convert appropriately
            if (reader.TryGetDateTime(out var dateTime))
            {
                return dateTime; // Keep as-is, let application layer handle conversion
            }

            return default;
        }

        public override void Write(Utf8JsonWriter writer, DateTime value, JsonSerializerOptions options)
        {
            // Convert UTC to Tashkent time (GMT+5) before writing to JSON
            DateTime tashkentTime;

            if (value.Kind == DateTimeKind.Utc)
            {
                tashkentTime = TimeZoneInfo.ConvertTimeFromUtc(value, TashkentTimeZone);
            }
            else if (value.Kind == DateTimeKind.Local)
            {
                var utc = value.ToUniversalTime();
                tashkentTime = TimeZoneInfo.ConvertTimeFromUtc(utc, TashkentTimeZone);
            }
            else
            {
                // Unspecified - assume UTC
                tashkentTime = TimeZoneInfo.ConvertTimeFromUtc(value, TashkentTimeZone);
            }

            writer.WriteStringValue(tashkentTime);
        }
    }

    /// <summary>
    /// Nullable DateTime version of TashkentTimeJsonConverter
    /// </summary>
    public class TashkentTimeJsonConverterNullable : JsonConverter<DateTime?>
    {
        private static readonly TimeZoneInfo TashkentTimeZone = TimeZoneInfo.FindSystemTimeZoneById("Central Asia Standard Time");

        public override DateTime? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            if (reader.TokenType == JsonTokenType.Null)
                return null;

            if (reader.TryGetDateTime(out var dateTime))
            {
                return dateTime;
            }

            return null;
        }

        public override void Write(Utf8JsonWriter writer, DateTime? value, JsonSerializerOptions options)
        {
            if (!value.HasValue)
            {
                writer.WriteNullValue();
                return;
            }

            DateTime tashkentTime;
            var dateTimeValue = value.Value;

            if (dateTimeValue.Kind == DateTimeKind.Utc)
            {
                tashkentTime = TimeZoneInfo.ConvertTimeFromUtc(dateTimeValue, TashkentTimeZone);
            }
            else if (dateTimeValue.Kind == DateTimeKind.Local)
            {
                var utc = dateTimeValue.ToUniversalTime();
                tashkentTime = TimeZoneInfo.ConvertTimeFromUtc(utc, TashkentTimeZone);
            }
            else
            {
                tashkentTime = TimeZoneInfo.ConvertTimeFromUtc(dateTimeValue, TashkentTimeZone);
            }

            writer.WriteStringValue(tashkentTime);
        }
    }
}
