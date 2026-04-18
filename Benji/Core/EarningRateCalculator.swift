import Foundation

/// Pure-Swift representation of the user's earning settings, used by the
/// rate calculator and by data export. The SwiftData `AppSettings` model
/// converts to/from this type.
public struct EarningSettings: Equatable, Codable, Sendable {
    public var incomeType: IncomeType
    public var incomeAmount: Double
    public var hoursPerWeek: Double
    public var realWageEnabled: Bool
    public var monthlyFixedExpenses: Double

    public init(incomeType: IncomeType = .hourly,
                incomeAmount: Double = 10,
                hoursPerWeek: Double = 40,
                realWageEnabled: Bool = false,
                monthlyFixedExpenses: Double = 0) {
        self.incomeType = incomeType
        self.incomeAmount = incomeAmount
        self.hoursPerWeek = hoursPerWeek
        self.realWageEnabled = realWageEnabled
        self.monthlyFixedExpenses = monthlyFixedExpenses
    }
}

/// Computes the user's effective earnings per minute given their income
/// configuration. Mirrors the formula used in the original web app:
///
/// ```
/// hourly  -> amount / 60
/// monthly -> amount / (hours/week * (52/12)) / 60
/// annual  -> amount / (hours/week * 52) / 60
/// ```
///
/// When real-wage mode is enabled the user's monthly fixed expenses are
/// subtracted (proportionally per minute), floored at zero. The original
/// implementation chose `52 / 12 ≈ 4.333` weeks per month — a standard
/// payroll approximation that we preserve verbatim.
public enum EarningRateCalculator {
    public static let weeksPerMonth: Double = 52.0 / 12.0

    public static func perMinute(_ s: EarningSettings) -> Double {
        guard s.hoursPerWeek > 0, s.incomeAmount > 0 else { return 0 }

        var perMin: Double
        switch s.incomeType {
        case .hourly:
            perMin = s.incomeAmount / 60
        case .monthly:
            perMin = s.incomeAmount / (s.hoursPerWeek * weeksPerMonth) / 60
        case .annual:
            perMin = s.incomeAmount / (s.hoursPerWeek * 52) / 60
        }

        if s.realWageEnabled, s.monthlyFixedExpenses > 0 {
            let expensesPerMin = s.monthlyFixedExpenses / (s.hoursPerWeek * weeksPerMonth) / 60
            perMin = max(0, perMin - expensesPerMin)
        }
        return perMin
    }

    /// Convert a money amount to minutes of work using the supplied rate.
    public static func minutes(forAmount amount: Double, rate: Double) -> Double {
        guard rate > 0, amount > 0 else { return 0 }
        return amount / rate
    }
}
