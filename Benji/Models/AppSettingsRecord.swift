import Foundation
import SwiftData

@Model
final class AppSettingsRecord {
    var incomeTypeRaw: String
    var incomeAmount: Double
    var hoursPerWeek: Double
    var realWageEnabled: Bool
    var monthlyFixedExpenses: Double
    var onboardingComplete: Bool

    init(incomeTypeRaw: String = IncomeType.hourly.rawValue,
         incomeAmount: Double = 10,
         hoursPerWeek: Double = 40,
         realWageEnabled: Bool = false,
         monthlyFixedExpenses: Double = 0,
         onboardingComplete: Bool = false) {
        self.incomeTypeRaw = incomeTypeRaw
        self.incomeAmount = incomeAmount
        self.hoursPerWeek = hoursPerWeek
        self.realWageEnabled = realWageEnabled
        self.monthlyFixedExpenses = monthlyFixedExpenses
        self.onboardingComplete = onboardingComplete
    }

    var incomeType: IncomeType {
        get { IncomeType(rawValue: incomeTypeRaw) ?? .hourly }
        set { incomeTypeRaw = newValue.rawValue }
    }

    var asEarningSettings: EarningSettings {
        EarningSettings(incomeType: incomeType,
                        incomeAmount: incomeAmount,
                        hoursPerWeek: hoursPerWeek,
                        realWageEnabled: realWageEnabled,
                        monthlyFixedExpenses: monthlyFixedExpenses)
    }

    func apply(_ s: EarningSettings) {
        incomeType = s.incomeType
        incomeAmount = s.incomeAmount
        hoursPerWeek = s.hoursPerWeek
        realWageEnabled = s.realWageEnabled
        monthlyFixedExpenses = s.monthlyFixedExpenses
    }
}
