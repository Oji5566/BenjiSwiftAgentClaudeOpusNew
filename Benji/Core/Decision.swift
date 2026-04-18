import Foundation

/// A user's decision about a calculated purchase.
///
/// Mirrors the web app's `decision` strings (`buy`, `skip`, `watchlist`).
/// The original app also accepted `watch_list` and `give_up`; those are
/// normalised to canonical values when read.
public enum Decision: String, CaseIterable, Codable, Identifiable, Sendable {
    case buy
    case skip
    case watchlist

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .buy:       return "Bought"
        case .skip:      return "Skipped"
        case .watchlist: return "Watchlist"
        }
    }

    public var verb: String {
        switch self {
        case .buy:       return "Buy"
        case .skip:      return "Skip"
        case .watchlist: return "Watchlist"
        }
    }

    /// Normalises legacy / alternate decision strings to a canonical case.
    public static func normalise(_ raw: String) -> Decision? {
        switch raw {
        case "buy":                 return .buy
        case "skip", "give_up":     return .skip
        case "watchlist", "watch_list": return .watchlist
        default:                    return nil
        }
    }
}
