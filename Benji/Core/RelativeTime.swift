import Foundation

/// Pre-iOS-26 SF-Symbol-friendly relative time formatter, matching the
/// strings the web app produced (`Just now`, `5m ago`, `2h ago`, `Yesterday`,
/// `3d ago`, then `MMM d`).
public enum RelativeTime {
    public static func format(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        let diff = now.timeIntervalSince(date)
        let mins = Int(diff / 60)
        if mins < 1 { return "Just now" }
        if mins < 60 { return "\(mins)m ago" }
        let hrs = mins / 60
        if hrs < 24 { return "\(hrs)h ago" }
        let days = hrs / 24
        if days == 1 { return "Yesterday" }
        if days < 7 { return "\(days)d ago" }
        let f = DateFormatter()
        f.calendar = calendar
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}
