import XCTest

final class ReminderSortingTests: XCTestCase {

    func testSortsByDueDateAscending() {
        let now = Date()
        let reminders = [
            ReminderItem(title: "Later", dueDate: now.addingTimeInterval(200), creationDate: now, externalID: nil),
            ReminderItem(title: "Soon", dueDate: now.addingTimeInterval(100), creationDate: now, externalID: nil),
            ReminderItem(title: "Earliest", dueDate: now.addingTimeInterval(50), creationDate: now, externalID: nil),
        ]
        let sorted = sortReminders(reminders)
        XCTAssertEqual(sorted.map(\.title), ["Earliest", "Soon", "Later"])
    }

    func testDueDateItemsBeforeNoDueDateItems() {
        let now = Date()
        let reminders = [
            ReminderItem(title: "No Due", dueDate: nil, creationDate: now, externalID: nil),
            ReminderItem(title: "Has Due", dueDate: now.addingTimeInterval(100), creationDate: now, externalID: nil),
        ]
        let sorted = sortReminders(reminders)
        XCTAssertEqual(sorted.map(\.title), ["Has Due", "No Due"])
    }

    func testNoDueDateFallsBackToCreationDateAscending() {
        let now = Date()
        let reminders = [
            ReminderItem(title: "Newer", dueDate: nil, creationDate: now.addingTimeInterval(200), externalID: nil),
            ReminderItem(title: "Older", dueDate: nil, creationDate: now.addingTimeInterval(100), externalID: nil),
            ReminderItem(title: "Oldest", dueDate: nil, creationDate: now, externalID: nil),
        ]
        let sorted = sortReminders(reminders)
        XCTAssertEqual(sorted.map(\.title), ["Oldest", "Older", "Newer"])
    }

    func testNilCreationDateTreatedAsDistantPast() {
        let now = Date()
        let reminders = [
            ReminderItem(title: "Has Creation", dueDate: nil, creationDate: now, externalID: nil),
            ReminderItem(title: "No Creation", dueDate: nil, creationDate: nil, externalID: nil),
        ]
        let sorted = sortReminders(reminders)
        XCTAssertEqual(sorted.map(\.title), ["No Creation", "Has Creation"])
    }

    func testMixedDueDateAndNoDueDate() {
        let now = Date()
        let reminders = [
            ReminderItem(title: "No Due Old", dueDate: nil, creationDate: now, externalID: nil),
            ReminderItem(title: "Due Later", dueDate: now.addingTimeInterval(200), creationDate: now, externalID: nil),
            ReminderItem(title: "No Due New", dueDate: nil, creationDate: now.addingTimeInterval(100), externalID: nil),
            ReminderItem(title: "Due Soon", dueDate: now.addingTimeInterval(100), creationDate: now, externalID: nil),
        ]
        let sorted = sortReminders(reminders)
        XCTAssertEqual(sorted.map(\.title), ["Due Soon", "Due Later", "No Due Old", "No Due New"])
    }

    func testEmptyArrayReturnsEmpty() {
        let sorted = sortReminders([])
        XCTAssertTrue(sorted.isEmpty)
    }
}
