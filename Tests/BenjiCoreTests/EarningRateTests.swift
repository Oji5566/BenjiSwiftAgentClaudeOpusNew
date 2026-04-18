import XCTest
@testable import BenjiCore

final class EarningRateTests: XCTestCase {

    func testHourlyRate() {
        // $60/hr → $1/min
        let s = EarningSettings(incomeType: .hourly, incomeAmount: 60)
        XCTAssertEqual(EarningRateCalculator.perMinute(s), 1.0, accuracy: 1e-9)
    }

    func testMonthlyRateMatchesWebFormula() {
        // $5000/mo at 40hr/wk: 5000 / (40 * 52/12) / 60
        let s = EarningSettings(incomeType: .monthly, incomeAmount: 5000, hoursPerWeek: 40)
        let expected = 5000.0 / (40 * (52.0 / 12.0)) / 60.0
        XCTAssertEqual(EarningRateCalculator.perMinute(s), expected, accuracy: 1e-9)
    }

    func testAnnualRate() {
        // $104,000/yr at 40hr/wk = $50/hr → $50/60 per min
        let s = EarningSettings(incomeType: .annual, incomeAmount: 104_000, hoursPerWeek: 40)
        XCTAssertEqual(EarningRateCalculator.perMinute(s), 50.0 / 60.0, accuracy: 1e-9)
    }

    func testZeroHoursReturnsZero() {
        let s = EarningSettings(incomeType: .monthly, incomeAmount: 5000, hoursPerWeek: 0)
        XCTAssertEqual(EarningRateCalculator.perMinute(s), 0)
    }

    func testZeroAmountReturnsZero() {
        let s = EarningSettings(incomeType: .hourly, incomeAmount: 0)
        XCTAssertEqual(EarningRateCalculator.perMinute(s), 0)
    }

    func testRealWageDeductsExpenses() {
        // hourly $60 → 1/min. Monthly expenses 1733.33 ≈ same per minute, so adjusted ≈ 0.
        let monthlyHours = 40 * (52.0 / 12.0)
        let expenses = monthlyHours * 60 // exactly cancels $60/hr
        let s = EarningSettings(incomeType: .hourly,
                                incomeAmount: 60,
                                hoursPerWeek: 40,
                                realWageEnabled: true,
                                monthlyFixedExpenses: expenses)
        XCTAssertEqual(EarningRateCalculator.perMinute(s), 0, accuracy: 1e-9)
    }

    func testRealWageNeverGoesNegative() {
        let s = EarningSettings(incomeType: .hourly,
                                incomeAmount: 10,
                                hoursPerWeek: 40,
                                realWageEnabled: true,
                                monthlyFixedExpenses: 999_999)
        XCTAssertEqual(EarningRateCalculator.perMinute(s), 0, accuracy: 1e-9)
    }

    func testRealWageOffIgnoresExpenses() {
        let s = EarningSettings(incomeType: .hourly,
                                incomeAmount: 60,
                                hoursPerWeek: 40,
                                realWageEnabled: false,
                                monthlyFixedExpenses: 100_000)
        XCTAssertEqual(EarningRateCalculator.perMinute(s), 1.0, accuracy: 1e-9)
    }

    func testMinutesForAmount() {
        XCTAssertEqual(EarningRateCalculator.minutes(forAmount: 5, rate: 0.5), 10, accuracy: 1e-9)
        XCTAssertEqual(EarningRateCalculator.minutes(forAmount: 0, rate: 0.5), 0)
        XCTAssertEqual(EarningRateCalculator.minutes(forAmount: 5, rate: 0), 0)
    }
}
