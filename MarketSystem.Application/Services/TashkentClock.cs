using MarketSystem.Application.Interfaces;

namespace MarketSystem.Application.Services;

public sealed class TashkentClock : ITashkentClock
{
    private readonly TimeZoneInfo _tz;

    public TashkentClock(TimeZoneInfo tashkentTimeZone)
    {
        _tz = tashkentTimeZone;
    }

    public DateTime UtcNow => DateTime.UtcNow;

    public DateTime TodayLocal => TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, _tz).Date;

    public (DateTime UtcStart, DateTime UtcEnd) LocalDayToUtcRange(DateTime localDate)
    {
        // Treat the input as a Tashkent calendar day at midnight local time.
        var localStart = DateTime.SpecifyKind(localDate.Date, DateTimeKind.Unspecified);
        var localEnd = localStart.AddDays(1);

        var utcStart = TimeZoneInfo.ConvertTimeToUtc(localStart, _tz);
        var utcEnd = TimeZoneInfo.ConvertTimeToUtc(localEnd, _tz);
        return (utcStart, utcEnd);
    }

    public DateTime ToLocal(DateTime utc)
    {
        var utcKind = utc.Kind == DateTimeKind.Unspecified
            ? DateTime.SpecifyKind(utc, DateTimeKind.Utc)
            : utc;
        return TimeZoneInfo.ConvertTimeFromUtc(utcKind.ToUniversalTime(), _tz);
    }
}
