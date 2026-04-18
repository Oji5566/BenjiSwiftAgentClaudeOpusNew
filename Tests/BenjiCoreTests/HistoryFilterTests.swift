import XCTest
@testable import BenjiCore

final class HistoryFilterTests: XCTestCase {
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        c.firstWeekday = 1
        return c
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
    }

    func testDailyKeepsTodayOnly() {
        let now = date(2026, 4, 18)
        XCTAssertTrue(EntryFilter.keep(timestamp: date(2026, 4, 18, 9), in: .daily, now: now, calendar: cal))
        XCTAssertFalse(EntryFilter.keep(timestamp: date(2026, 4, 17, 23), in: .daily, now: now, calendar: cal))
    }

    func testWeeklyKeepsCurrentSundayWeek() {
        // 2026-04-18 is a Saturday → week starts Sunday Apr 12
        let now = date(2026, 4, 18)
        XCTAssertTrue(EntryFilter.keep(timestamp: date(2026, 4, 12), in: .weekly, now: now, calendar: cal))
        XCTAssertTrue(EntryFilter.keep(timestamp: date(2026, 4, 14), in: .weekly, now: now, calendar: cal))
        XCTAssertFalse(EntryFilter.keep(timestamp: date(2026, 4, 11), in: .weekly, now: now, calendar: cal))
    }

    func testMonthlyKeepsSameMonthYear() {
        let now = date(2026, 4, 18)
        XCTAssertTrue(EntryFilter.keep(timestamp: date(2026, 4, 1), in: .monthly, now: now, calendar: cal))
        XCTAssertFalse(EntryFilter.keep(timestamp: date(2026, 3, 31), in: .monthly, now: now, calendar: cal))
        XCTAssertFalse(EntryFilter.keep(timestamp: date(2025, 4, 18), in: .monthly, now: now, calendar: cal))
    }

    func testYearlyKeepsSameYear() {
        let now = date(2026, 6, 1)
        XCTAssertTrue(EntryFilter.keep(timestamp: date(2026, 1, 1), in: .yearly, now: now, calendar: cal))
        XCTAssertFalse(EntryFilter.keep(timestamp: date(2025, 12, 31), in: .yearly, now: now, calendar: cal))
    }

    func testStatsAggregation() {
        let entries: [EntryDTO] = [
            .init(id: "a", amount: 10, minutes: 20, decision: .buy, name: "x", category: "c", timestamp: Date()),
            .init(id: "b", amount: 5,  minutes: 10, decision: .skip, name: "y", category: "c", timestamp: Date()),
            .init(id: "c", amount: 15, minutes: 30, decision: .buy, name: "z", category: "c", timestamp: Date()),
        ]
        let s = HistoryStats(entries: entries)
        XCTAssertEqual(s.total, 3)
        XCTAssertEqual(s.totalAmount, 30, accuracy: 1e-9)
        XCTAssertEqual(s.boughtCount, 2)
        XCTAssertEqual(s.boughtAmount, 25, accuracy: 1e-9)
        XCTAssertEqual(s.boughtMinutes, 50, accuracy: 1e-9)
        XCTAssertEqual(s.skippedCount, 1)
        XCTAssertEqual(s.skippedMinutes, 10, accuracy: 1e-9)
        XCTAssertEqual(s.boughtPercent, 67)
        XCTAssertEqual(s.skippedPercent, 33)
    }

    func testEmptyStatsAreZero() {
        let s = HistoryStats(entries: [])
        XCTAssertEqual(s.total, 0)
        XCTAssertEqual(s.boughtPercent, 0)
        XCTAssertEqual(s.skippedPercent, 100)
    }

    func testDecisionNormalisation() {
        XCTAssertEqual(Decision.normalise("watch_list"), .watchlist)
        XCTAssertEqual(Decision.normalise("give_up"), .skip)
        XCTAssertEqual(Decision.normalise("buy"), .buy)
        XCTAssertNil(Decision.normalise("nope"))
    }
}
