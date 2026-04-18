import Foundation

/// Time-window filter used by the History tab.
public enum HistoryFilter: String, CaseIterable, Identifiable, Sendable {
    case daily, weekly, monthly, yearly

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .daily:   return "Day"
        case .weekly:  return "Week"
        case .monthly: return "Month"
        case .yearly:  return "Year"
        }
    }
}

public enum EntryFilter {

    /// Apply the History tab's daily / weekly / monthly / yearly filter to a
    /// list of entry timestamps. Mirrors the JS `getFilteredEntries` logic
    /// but uses `Calendar.current` for proper locale-aware date math.
    public static func keep(timestamp ts: Date, in period: HistoryFilter, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        let cal = calendar
        switch period {
        case .daily:
            return cal.isDate(ts, inSameDayAs: now)
        case .weekly:
            // Match the JS behaviour: week starts on Sunday (`now.getDay()`).
            var sundayCalendar = cal
            sundayCalendar.firstWeekday = 1 // Sunday
            guard let weekStart = sundayCalendar.dateInterval(of: .weekOfYear, for: now)?.start else {
                return false
            }
            return ts >= weekStart && ts <= now.addingTimeInterval(86_400) // include "future today"
        case .monthly:
            return cal.component(.month, from: ts) == cal.component(.month, from: now)
                && cal.component(.year, from: ts) == cal.component(.year, from: now)
        case .yearly:
            return cal.component(.year, from: ts) == cal.component(.year, from: now)
        }
    }
}
