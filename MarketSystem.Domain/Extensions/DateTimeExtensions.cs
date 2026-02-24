using System.Text.Json;

namespace MarketSystem.Domain.Extensions
{
    /// <summary>
    /// DateTime extensions for GMT+5 (Tashkent Time) conversion
    /// </summary>
    public static class DateTimeExtensions
    {
        private static readonly TimeZoneInfo TashkentTimeZone = TimeZoneInfo.FindSystemTimeZoneById("Central Asia Standard Time");

        /// <summary>
        /// Convert DateTime to GMT+5 (Tashkent Time)
        /// </summary>
        public static DateTime ToTashkentTime(this DateTime dateTime)
        {
            if (dateTime.Kind == DateTimeKind.Local)
            {
                // Convert local to UTC first, then to Tashkent time
                var utc = dateTime.ToUniversalTime();
                return TimeZoneInfo.ConvertTimeFromUtc(utc, TashkentTimeZone);
            }
            else if (dateTime.Kind == DateTimeKind.Utc)
            {
                // Convert UTC to Tashkent time
                return TimeZoneInfo.ConvertTimeFromUtc(dateTime, TashkentTimeZone);
            }
            else
            {
                // Unspecified - assume UTC and convert
                return TimeZoneInfo.ConvertTimeFromUtc(dateTime, TashkentTimeZone);
            }
        }

        /// <summary>
        /// Convert DateTime to GMT+5 (Tashkent Time) - Nullable version
        /// </summary>
        public static DateTime? ToTashkentTime(this DateTime? dateTime)
        {
            if (!dateTime.HasValue)
                return null;

            return dateTime.Value.ToTashkentTime();
        }

        /// <summary>
        /// Get current UTC time (recommended for database storage)
        /// </summary>
        public static DateTime UtcNow()
        {
            return DateTime.UtcNow;
        }

        /// <summary>
        /// Get current time in GMT+5 (Tashkent Time)
        /// </summary>
        public static DateTime GetTashkentNow()
        {
            return TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TashkentTimeZone);
        }

        /// <summary>
        /// Convert Tashkent time to UTC (for database storage)
        /// </summary>
        public static DateTime ToUtcFromTashkent(this DateTime tashkentTime)
        {
            if (tashkentTime.Kind == DateTimeKind.Utc)
                return tashkentTime;

            return TimeZoneInfo.ConvertTimeToUtc(tashkentTime, TashkentTimeZone);
        }
    }
}
