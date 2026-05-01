import XCTest

final class ReminderDueDateFormatterTests: XCTestCase {

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return cal
    }()
    private let locale = Locale(identifier: "en_US")

    private func date(
        _ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year, month: month, day: day, hour: hour, minute: minute
            ))!
    }

    private func format(
        _ due: Date, includesTime: Bool, now: Date
    ) -> ReminderDueDateLabel {
        formatReminderDueDate(due, includesTime: includesTime, now: now, calendar: calendar, locale: locale)
    }

    // iOS 16+ Date.FormatStyle inserts a narrow no-break space (U+202F) before AM/PM.
    private let nbsp = "\u{202F}"

    // MARK: - Future (>tomorrow)

    func testFutureWithTime() {
        let now = date(2026, 4, 30, 10, 53)
        let due = date(2026, 5, 5, 6, 0)
        let result = format(due, includesTime: true, now: now)
        XCTAssertEqual(result.text, "May 5, 2026 at 6:00\(nbsp)AM")
        XCTAssertFalse(result.isOverdue)
    }

    func testFutureDateOnly() {
        let now = date(2026, 4, 30, 10, 53)
        let due = date(2026, 5, 5)
        let result = format(due, includesTime: false, now: now)
        XCTAssertEqual(result.text, "May 5, 2026")
        XCTAssertFalse(result.isOverdue)
    }

    // MARK: - Tomorrow

    func testTomorrowWithTime() {
        let now = date(2026, 4, 30, 10, 53)
        let due = date(2026, 5, 1, 18, 0)
        let result = format(due, includesTime: true, now: now)
        XCTAssertEqual(result.text, "Tomorrow at 6:00\(nbsp)PM")
        XCTAssertFalse(result.isOverdue)
    }

    func testTomorrowDateOnly() {
        let now = date(2026, 4, 30, 10, 53)
        let due = date(2026, 5, 1)
        let result = format(due, includesTime: false, now: now)
        XCTAssertEqual(result.text, "Tomorrow")
        XCTAssertFalse(result.isOverdue)
    }

    // MARK: - Today

    func testTodayDateOnly() {
        let now = date(2026, 4, 30, 10, 53)
        let due = date(2026, 4, 30)
        let result = format(due, includesTime: false, now: now)
        XCTAssertEqual(result.text, "Today")
        XCTAssertFalse(result.isOverdue)
    }

    func testTodayTimeLater() {
        let now = date(2026, 4, 30, 10, 53)
        let due = date(2026, 4, 30, 18, 0)
        let result = format(due, includesTime: true, now: now)
        XCTAssertEqual(result.text, "Today at 6:00\(nbsp)PM")
        XCTAssertFalse(result.isOverdue)
    }

    func testTodayTimePassed() {
        let now = date(2026, 4, 30, 10, 53)
        let due = date(2026, 4, 30, 9, 0)
        let result = format(due, includesTime: true, now: now)
        XCTAssertEqual(result.text, "Today at 9:00\(nbsp)AM")
        XCTAssertTrue(result.isOverdue)
    }

    // Date-only "today" stays not overdue even when the clock is well past midnight,
    // because date-only reminders have the whole day to be completed.
    func testTodayDateOnlyAtEndOfDay() {
        let now = date(2026, 4, 30, 23, 59)
        let due = date(2026, 4, 30)
        let result = format(due, includesTime: false, now: now)
        XCTAssertEqual(result.text, "Today")
        XCTAssertFalse(result.isOverdue)
    }

    // MARK: - Yesterday

    func testYesterdayWithTime() {
        let now = date(2026, 4, 30, 10, 53)
        let due = date(2026, 4, 29, 6, 0)
        let result = format(due, includesTime: true, now: now)
        XCTAssertEqual(result.text, "Yesterday at 6:00\(nbsp)AM")
        XCTAssertTrue(result.isOverdue)
    }

    func testYesterdayDateOnly() {
        let now = date(2026, 4, 30, 10, 53)
        let due = date(2026, 4, 29)
        let result = format(due, includesTime: false, now: now)
        XCTAssertEqual(result.text, "Yesterday")
        XCTAssertTrue(result.isOverdue)
    }

    // MARK: - Past (>yesterday)

    func testPastWithTime() {
        let now = date(2026, 4, 30, 10, 53)
        let due = date(2026, 4, 28, 6, 0)
        let result = format(due, includesTime: true, now: now)
        XCTAssertEqual(result.text, "April 28, 2026 at 6:00\(nbsp)AM")
        XCTAssertTrue(result.isOverdue)
    }

    func testPastDateOnly() {
        let now = date(2026, 4, 30, 10, 53)
        let due = date(2026, 4, 28)
        let result = format(due, includesTime: false, now: now)
        XCTAssertEqual(result.text, "April 28, 2026")
        XCTAssertTrue(result.isOverdue)
    }
}
