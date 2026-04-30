import XCTest

final class StreakTests: XCTestCase {
    private var calendar: Calendar!
    private var engine: StreakEngine!
    private var now: Date!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        engine = StreakEngine()
        now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 29, hour: 10))!
    }

    func testNoOverdueIgnoresUndatedReminders() {
        let snapshot = StreakSnapshot(incompleteReminders: [
            StreakReminder(dueDate: nil),
        ])

        XCTAssertTrue(engine.qualifies(mode: .noOverdue, snapshot: snapshot, now: now, calendar: calendar))
    }

    func testNoOverdueFailsWithTimedOverdueReminder() {
        let snapshot = StreakSnapshot(incompleteReminders: [
            StreakReminder(dueDate: now.addingTimeInterval(-60), dueDateIncludesTime: true),
        ])

        XCTAssertFalse(engine.qualifies(mode: .noOverdue, snapshot: snapshot, now: now, calendar: calendar))
    }

    func testNoOverdueDoesNotTreatAllDayReminderDueTodayAsOverdue() {
        let today = calendar.startOfDay(for: now)
        let snapshot = StreakSnapshot(incompleteReminders: [
            StreakReminder(dueDate: today, dueDateIncludesTime: false),
        ])

        XCTAssertTrue(engine.qualifies(mode: .noOverdue, snapshot: snapshot, now: now, calendar: calendar))
    }

    func testNoOverdueTreatsAllDayReminderDueYesterdayAsOverdue() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
        let snapshot = StreakSnapshot(incompleteReminders: [
            StreakReminder(dueDate: yesterday, dueDateIncludesTime: false),
        ])

        XCTAssertFalse(engine.qualifies(mode: .noOverdue, snapshot: snapshot, now: now, calendar: calendar))
    }

    func testDailyProgressPassesWithCompletionToday() {
        let snapshot = StreakSnapshot(
            incompleteReminders: [StreakReminder(dueDate: nil)],
            completedTodayCount: 1
        )

        XCTAssertTrue(engine.qualifies(mode: .dailyProgress, snapshot: snapshot, now: now, calendar: calendar))
    }

    func testDailyProgressPassesWhenListIsEmpty() {
        let snapshot = StreakSnapshot(incompleteReminders: [], completedTodayCount: 0)

        XCTAssertTrue(engine.qualifies(mode: .dailyProgress, snapshot: snapshot, now: now, calendar: calendar))
    }

    func testDailyProgressFailsWithoutCompletionWhenListHasItems() {
        let snapshot = StreakSnapshot(incompleteReminders: [StreakReminder(dueDate: nil)], completedTodayCount: 0)

        XCTAssertFalse(engine.qualifies(mode: .dailyProgress, snapshot: snapshot, now: now, calendar: calendar))
    }

    func testEmptyListPassesOnlyWhenThereAreNoIncompleteReminders() {
        XCTAssertTrue(engine.qualifies(mode: .emptyList, snapshot: StreakSnapshot(incompleteReminders: []), now: now, calendar: calendar))
        XCTAssertFalse(engine.qualifies(mode: .emptyList, snapshot: StreakSnapshot(incompleteReminders: [StreakReminder(dueDate: nil)]), now: now, calendar: calendar))
    }

    func testStreakIncrementsOncePerLocalDay() {
        let state = StreakState(
            mode: .emptyList,
            listID: "list-1",
            currentCount: 2,
            bestCount: 2,
            lastQualifiedDay: calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
        )
        let snapshot = StreakSnapshot(incompleteReminders: [])

        let firstEvaluation = engine.evaluate(state: state, listID: "list-1", snapshot: snapshot, now: now, calendar: calendar)
        let secondEvaluation = engine.evaluate(state: firstEvaluation.state, listID: "list-1", snapshot: snapshot, now: now, calendar: calendar)

        XCTAssertEqual(firstEvaluation.state.currentCount, 3)
        XCTAssertEqual(firstEvaluation.state.bestCount, 3)
        XCTAssertEqual(secondEvaluation.state.currentCount, 3)
        XCTAssertEqual(secondEvaluation.state.bestCount, 3)
    }

    func testStreakResetsAfterMissedDay() {
        let state = StreakState(
            mode: .emptyList,
            listID: "list-1",
            currentCount: 4,
            bestCount: 4,
            lastQualifiedDay: calendar.date(byAdding: .day, value: -2, to: calendar.startOfDay(for: now))!
        )

        let evaluation = engine.evaluate(
            state: state,
            listID: "list-1",
            snapshot: StreakSnapshot(incompleteReminders: []),
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(evaluation.state.currentCount, 1)
        XCTAssertEqual(evaluation.state.bestCount, 4)
    }

    func testStreakResetsWhenTodayDoesNotQualify() {
        let state = StreakState(
            mode: .emptyList,
            listID: "list-1",
            currentCount: 4,
            bestCount: 4,
            lastQualifiedDay: calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
        )

        let evaluation = engine.evaluate(
            state: state,
            listID: "list-1",
            snapshot: StreakSnapshot(incompleteReminders: [StreakReminder(dueDate: nil)]),
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(evaluation.state.currentCount, 0)
        XCTAssertEqual(evaluation.state.bestCount, 4)
        XCTAssertNil(evaluation.state.lastQualifiedDay)
        XCTAssertFalse(evaluation.isQualifiedToday)
    }

    func testResetForListOrModeClearsCurrentButPreservesBestCount() {
        let state = StreakState(
            mode: .noOverdue,
            listID: "old-list",
            currentCount: 5,
            bestCount: 8,
            lastQualifiedDay: calendar.startOfDay(for: now)
        )

        let reset = state.reset(for: "new-list", mode: .dailyProgress)

        XCTAssertEqual(reset.mode, .dailyProgress)
        XCTAssertEqual(reset.listID, "new-list")
        XCTAssertEqual(reset.currentCount, 0)
        XCTAssertEqual(reset.bestCount, 8)
        XCTAssertNil(reset.lastQualifiedDay)
    }

    func testEvaluatePreservesBestCountWhenSwitchingLists() {
        let state = StreakState(
            mode: .emptyList,
            listID: "list-1",
            currentCount: 3,
            bestCount: 9,
            lastQualifiedDay: calendar.startOfDay(for: now)
        )

        let evaluation = engine.evaluate(
            state: state,
            listID: "list-2",
            snapshot: StreakSnapshot(incompleteReminders: []),
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(evaluation.state.listID, "list-2")
        XCTAssertEqual(evaluation.state.currentCount, 1)
        XCTAssertEqual(evaluation.state.bestCount, 9)
    }
}

final class StreakStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "test-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testDefaultsToNoOverdueEmptyState() {
        let store = StreakStore(defaults: defaults)

        XCTAssertEqual(store.state, .empty)
    }

    func testPersistsStateAcrossInstances() {
        var store = StreakStore(defaults: defaults)
        let lastQualifiedDay = Date(timeIntervalSince1970: 1_777_474_800)
        store.state = StreakState(
            mode: .dailyProgress,
            listID: "calendar-1",
            currentCount: 3,
            bestCount: 7,
            lastQualifiedDay: lastQualifiedDay
        )

        let restored = StreakStore(defaults: defaults).state

        XCTAssertEqual(restored.mode, .dailyProgress)
        XCTAssertEqual(restored.listID, "calendar-1")
        XCTAssertEqual(restored.currentCount, 3)
        XCTAssertEqual(restored.bestCount, 7)
        XCTAssertEqual(restored.lastQualifiedDay, lastQualifiedDay)
    }
}
