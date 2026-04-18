import Foundation

/// How a user expresses their income. Mirrors the original web app's
/// `incomeType` field (`hourly` / `monthly` / `annual`).
public enum IncomeType: String, CaseIterable, Codable, Identifiable, Sendable {
    case hourly
    case monthly
    case annual

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .hourly:  return "Hourly"
        case .monthly: return "Monthly"
        case .annual:  return "Annual"
        }
    }

    public var amountFieldLabel: String {
        switch self {
        case .hourly:  return "Hourly Rate"
        case .monthly: return "Monthly Salary"
        case .annual:  return "Annual Salary"
        }
    }
}
