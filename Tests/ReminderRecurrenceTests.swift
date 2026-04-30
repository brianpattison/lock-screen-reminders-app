import XCTest

final class ReminderRecurrenceTests: XCTestCase {

    func testSingularDaily() {
        XCTAssertEqual(ReminderRecurrence.interval(frequency: .daily, count: 1).displayText, "Daily")
    }

    func testSingularWeekly() {
        XCTAssertEqual(ReminderRecurrence.interval(frequency: .weekly, count: 1).displayText, "Weekly")
    }

    func testSingularMonthly() {
        XCTAssertEqual(ReminderRecurrence.interval(frequency: .monthly, count: 1).displayText, "Monthly")
    }

    func testSingularYearly() {
        XCTAssertEqual(ReminderRecurrence.interval(frequency: .yearly, count: 1).displayText, "Yearly")
    }

    func testIntervalDays() {
        XCTAssertEqual(ReminderRecurrence.interval(frequency: .daily, count: 3).displayText, "Every 3 days")
    }

    func testIntervalWeeks() {
        XCTAssertEqual(ReminderRecurrence.interval(frequency: .weekly, count: 2).displayText, "Every 2 weeks")
    }

    func testIntervalMonths() {
        XCTAssertEqual(ReminderRecurrence.interval(frequency: .monthly, count: 6).displayText, "Every 6 months")
    }

    func testIntervalYears() {
        XCTAssertEqual(ReminderRecurrence.interval(frequency: .yearly, count: 5).displayText, "Every 5 years")
    }

    func testComplex() {
        XCTAssertEqual(ReminderRecurrence.complex.displayText, "Repeats")
    }

    // Defensive: a count <= 1 should always render the singular form, regardless of how the
    // recurrence got built. EventKit clamps to a minimum of 1 in our converter, but the model
    // itself doesn't enforce it.
    func testZeroOrNegativeCountFallsBackToSingular() {
        XCTAssertEqual(ReminderRecurrence.interval(frequency: .weekly, count: 0).displayText, "Weekly")
        XCTAssertEqual(ReminderRecurrence.interval(frequency: .monthly, count: -1).displayText, "Monthly")
    }
}
