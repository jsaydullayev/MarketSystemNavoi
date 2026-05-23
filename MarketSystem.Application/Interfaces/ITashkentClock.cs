namespace MarketSystem.Application.Interfaces;

/// <summary>
/// Provides Asia/Tashkent (GMT+5) date arithmetic without server-locale ambiguity.
/// Reports and "today's" queries must be anchored to the local business day, not UTC,
/// so that early-morning sales (00:00–05:00 Tashkent = previous-day UTC) land in the
/// right report.
/// </summary>
public interface ITashkentClock
{
    /// <summary>Current instant in UTC.</summary>
    DateTime UtcNow { get; }

    /// <summary>Current wall-clock time in Tashkent (includes time-of-day).
    /// Use this for user-facing timestamps like "report generated at" or
    /// download file names — anything that should reflect the operator's
    /// local time regardless of which timezone the server runs in.</summary>
    DateTime NowLocal { get; }

    /// <summary>Current calendar date in Tashkent (date-only, Kind=Unspecified).</summary>
    DateTime TodayLocal { get; }

    /// <summary>
    /// Convert a Tashkent-local calendar date into the UTC half-open range
    /// [start, end) that covers that local day. The input's time-of-day is ignored.
    /// </summary>
    (DateTime UtcStart, DateTime UtcEnd) LocalDayToUtcRange(DateTime localDate);

    /// <summary>Convert a UTC instant to the Tashkent wall-clock time.</summary>
    DateTime ToLocal(DateTime utc);
}
