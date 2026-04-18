import XCTest
@testable import BenjiCore

final class FormattingAndExportTests: XCTestCase {

    func testCurrencyFormat() {
        XCTAssertEqual(Formatters.currency(0), "$0.00")
        XCTAssertEqual(Formatters.currency(1.234), "$1.23")
        XCTAssertEqual(Formatters.currency(1000), "$1,000.00")
    }

    func testMinutesFormat() {
        XCTAssertEqual(Formatters.minutes(0), "0 mins")
        XCTAssertEqual(Formatters.minutes(0.5), "30 secs")
        XCTAssertEqual(Formatters.minutes(1), "1 min")
        XCTAssertEqual(Formatters.minutes(45), "45 mins")
        XCTAssertEqual(Formatters.minutes(60), "1 hr")
        XCTAssertEqual(Formatters.minutes(125), "2 hrs 5 mins")
        XCTAssertEqual(Formatters.minutes(61), "1 hr 1 min")
    }

    func testRatePerMinute() {
        XCTAssertEqual(Formatters.ratePerMinute(0.1666666), "$0.1667 / min")
    }

    func testCalculatorInputApply() {
        XCTAssertEqual(CalculatorInput.apply(key: "5", to: "0"), "5")
        XCTAssertEqual(CalculatorInput.apply(key: "5", to: "5"), "55")
        XCTAssertEqual(CalculatorInput.apply(key: ".", to: "5"), "5.")
        XCTAssertEqual(CalculatorInput.apply(key: ".", to: "5."), "5.")
        XCTAssertEqual(CalculatorInput.apply(key: "9", to: "5.12"), "5.12") // max 2 decimals
        XCTAssertEqual(CalculatorInput.apply(key: "backspace", to: "12"), "1")
        XCTAssertEqual(CalculatorInput.apply(key: "backspace", to: "1"), "0")
    }

    func testCalculatorInputIntegerLimit() {
        var s = "1"
        for _ in 0..<7 { s = CalculatorInput.apply(key: "2", to: s) }
        XCTAssertEqual(s, "12222222") // 8 digits
        // 9th digit should be ignored
        XCTAssertEqual(CalculatorInput.apply(key: "3", to: s), "12222222")
    }

    func testExportRoundTrip() throws {
        let entries: [EntryDTO] = [
            .init(id: "1", amount: 5, minutes: 10, decision: .buy, name: "Coffee", category: "☕ Coffee", timestamp: Date(timeIntervalSince1970: 0))
        ]
        let payload = ExportPayload(
            username: "alex",
            exportedAt: Date(timeIntervalSince1970: 1_700_000_000),
            settings: EarningSettingsDTO(EarningSettings(incomeType: .hourly, incomeAmount: 30, hoursPerWeek: 40), onboardingComplete: true),
            categories: ["☕ Coffee"],
            entries: entries
        )
        let data = try ExportEncoder.encode(payload)
        let decoded = try ExportEncoder.decode(data)
        XCTAssertEqual(decoded, payload)
    }

    func testExportFilenameStable() {
        let date = Date(timeIntervalSince1970: 1_700_000_000) // 2023-11-14 22:13:20 UTC
        XCTAssertEqual(ExportEncoder.suggestedFilename(username: "alex", on: date),
                       "benji-alex-2023-11-14.json")
    }

    func testRelativeTimeBuckets() {
        let now = Date(timeIntervalSince1970: 100_000)
        XCTAssertEqual(RelativeTime.format(now, now: now), "Just now")
        XCTAssertEqual(RelativeTime.format(now.addingTimeInterval(-60), now: now), "1m ago")
        XCTAssertEqual(RelativeTime.format(now.addingTimeInterval(-3600), now: now), "1h ago")
        XCTAssertEqual(RelativeTime.format(now.addingTimeInterval(-86_400), now: now), "Yesterday")
        XCTAssertEqual(RelativeTime.format(now.addingTimeInterval(-3 * 86_400), now: now), "3d ago")
    }

    func testPasswordHasher() {
        // sha256("password") = 5e88...
        XCTAssertEqual(PasswordHasher.sha256Hex("password"),
                       "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8")
    }

    func testDefaultCategoriesEmoji() {
        XCTAssertEqual(DefaultCategories.emoji(of: "☕ Coffee"), "☕")
        XCTAssertEqual(DefaultCategories.emoji(of: "Plain"), "Plain")
    }
}
