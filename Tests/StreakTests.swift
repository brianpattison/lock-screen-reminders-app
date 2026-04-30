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
            StreakReminder(dueDate: nil)
        ])

        XCTAssertTrue(engine.qualifies(mode: .noOverdue, snapshot: snapshot, now: now, calendar: calendar))
    }

    func testNoOverdueFailsWithTimedOverdueReminder() {
        let snapshot = StreakSnapshot(incompleteReminders: [
            StreakReminder(dueDate: now.addingTimeInterval(-60), dueDateIncludesTime: true)
        ])

        XCTAssertFalse(engine.qualifies(mode: .noOverdue, snapshot: snapshot, now: now, calendar: calendar))
    }

    func testNoOverdueDoesNotTreatAllDayReminderDueTodayAsOverdue() {
        let today = calendar.startOfDay(for: now)
        let snapshot = StreakSnapshot(incompleteReminders: [
            StreakReminder(dueDate: today, dueDateIncludesTime: false)
        ])

        XCTAssertTrue(engine.qualifies(mode: .noOverdue, snapshot: snapshot, now: now, calendar: calendar))
    }

    func testNoOverdueTreatsAllDayReminderDueYesterdayAsOverdue() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
        let snapshot = StreakSnapshot(incompleteReminders: [
            StreakReminder(dueDate: yesterday, dueDateIncludesTime: false)
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
        XCTAssertTrue(
            engine.qualifies(
                mode: .emptyList, snapshot: StreakSnapshot(incompleteReminders: []), now: now, calendar: calendar))
        XCTAssertFalse(
            engine.qualifies(
                mode: .emptyList, snapshot: StreakSnapshot(incompleteReminders: [StreakReminder(dueDate: nil)]),
                now: now, calendar: calendar))
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

        let firstEvaluation = engine.evaluate(
            state: state, listID: "list-1", snapshot: snapshot, now: now, calendar: calendar)
        let secondEvaluation = engine.evaluate(
            state: firstEvaluation.state, listID: "list-1", snapshot: snapshot, now: now, calendar: calendar)

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

    func testStreakStaysAliveWhenYesterdayQualifiedButTodayNotYet() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
        let state = StreakState(
            mode: .emptyList,
            listID: "list-1",
            currentCount: 4,
            bestCount: 4,
            lastQualifiedDay: yesterday
        )

        let evaluation = engine.evaluate(
            state: state,
            listID: "list-1",
            snapshot: StreakSnapshot(incompleteReminders: [StreakReminder(dueDate: nil)]),
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(evaluation.state.currentCount, 4)
        XCTAssertEqual(evaluation.state.bestCount, 4)
        XCTAssertEqual(evaluation.state.lastQualifiedDay, yesterday)
        XCTAssertFalse(evaluation.isQualifiedToday)
    }

    func testEarnedTodayPreservesStreakCountWhenStateLaterFails() {
        // Day was already earned (lastQualifiedDay = today). Live state has since regressed
        // (a reminder is now overdue). Streak count and lastQualifiedDay are preserved, but
        // isQualifiedToday flips to false so the UI shows "Today: Clear overdue".
        let today = calendar.startOfDay(for: now)
        let state = StreakState(
            mode: .noOverdue,
            listID: "list-1",
            currentCount: 7,
            bestCount: 7,
            lastQualifiedDay: today
        )

        let evaluation = engine.evaluate(
            state: state,
            listID: "list-1",
            snapshot: StreakSnapshot(incompleteReminders: [
                StreakReminder(dueDate: now.addingTimeInterval(-60), dueDateIncludesTime: true)
            ]),
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(evaluation.state.currentCount, 7)
        XCTAssertEqual(evaluation.state.bestCount, 7)
        XCTAssertEqual(evaluation.state.lastQualifiedDay, today)
        XCTAssertFalse(evaluation.isQualifiedToday)
    }

    func testStreakResetsWhenLastQualifiedDayIsOlderAndTodayNotYet() {
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

    // MARK: - History-based evaluate (backfill)

    private func startOfDay(_ date: Date) -> Date { calendar.startOfDay(for: date) }
    private func dayOffset(_ days: Int) -> Date {
        calendar.date(byAdding: .day, value: days, to: startOfDay(now))!
    }
    private func hourOffset(_ hours: Int, from base: Date) -> Date {
        calendar.date(byAdding: .hour, value: hours, to: base)!
    }

    func testHistoryBackfillEmptyListAcrossInactiveGap() {
        let state = StreakState(
            mode: .emptyList,
            listID: "list-1",
            currentCount: 4,
            bestCount: 4,
            lastQualifiedDay: dayOffset(-2)
        )
        let history = StreakHistory(reminders: [])

        let evaluation = engine.evaluate(state: state, listID: "list-1", history: history, now: now, calendar: calendar)

        XCTAssertEqual(evaluation.state.currentCount, 6)
        XCTAssertEqual(evaluation.state.bestCount, 6)
        XCTAssertEqual(evaluation.state.lastQualifiedDay, startOfDay(now))
        XCTAssertTrue(evaluation.isQualifiedToday)
    }

    func testHistoryBackfillEmptyListBreaksWhenReminderWasIncomplete() {
        let state = StreakState(
            mode: .emptyList,
            listID: "list-1",
            currentCount: 4,
            bestCount: 4,
            lastQualifiedDay: dayOffset(-2)
        )
        let history = StreakHistory(reminders: [
            StreakHistoryReminder(creationDate: dayOffset(-1), completionDate: nil)
        ])

        let evaluation = engine.evaluate(state: state, listID: "list-1", history: history, now: now, calendar: calendar)

        XCTAssertEqual(evaluation.state.currentCount, 0)
        XCTAssertEqual(evaluation.state.bestCount, 4)
        XCTAssertNil(evaluation.state.lastQualifiedDay)
        XCTAssertFalse(evaluation.isQualifiedToday)
    }

    func testHistoryBackfillEmptyListCreditsDayWithBriefIncompleteWindow() {
        // Reminder existed only from noon to 3pm yesterday; list was empty the rest of the day.
        let yesterdayNoon = hourOffset(12, from: dayOffset(-1))
        let yesterday3pm = hourOffset(15, from: dayOffset(-1))
        let state = StreakState(
            mode: .emptyList,
            listID: "list-1",
            currentCount: 2,
            bestCount: 2,
            lastQualifiedDay: dayOffset(-2)
        )
        let history = StreakHistory(reminders: [
            StreakHistoryReminder(creationDate: yesterdayNoon, completionDate: yesterday3pm)
        ])

        let evaluation = engine.evaluate(state: state, listID: "list-1", history: history, now: now, calendar: calendar)

        XCTAssertEqual(evaluation.state.currentCount, 4)
        XCTAssertTrue(evaluation.isQualifiedToday)
    }

    func testHistoryBackfillDailyProgressViaCompletion() {
        let yesterdayNoon = hourOffset(12, from: dayOffset(-1))
        let state = StreakState(
            mode: .dailyProgress,
            listID: "list-1",
            currentCount: 3,
            bestCount: 3,
            lastQualifiedDay: dayOffset(-2)
        )
        // Reminder created 3 days ago, completed yesterday at noon. List empty rest of the time.
        let history = StreakHistory(reminders: [
            StreakHistoryReminder(creationDate: dayOffset(-3), completionDate: yesterdayNoon)
        ])

        let evaluation = engine.evaluate(state: state, listID: "list-1", history: history, now: now, calendar: calendar)

        XCTAssertEqual(evaluation.state.currentCount, 5)
        XCTAssertTrue(evaluation.isQualifiedToday)
    }

    func testHistoryBackfillDailyProgressBreaksOnGapDayWithoutCompletionOrEmpty() {
        // Reminder created 2 days ago, never completed. Yesterday: list non-empty, no completion.
        let state = StreakState(
            mode: .dailyProgress,
            listID: "list-1",
            currentCount: 3,
            bestCount: 5,
            lastQualifiedDay: dayOffset(-2)
        )
        let history = StreakHistory(reminders: [
            StreakHistoryReminder(creationDate: dayOffset(-2), completionDate: nil)
        ])

        let evaluation = engine.evaluate(state: state, listID: "list-1", history: history, now: now, calendar: calendar)

        XCTAssertEqual(evaluation.state.currentCount, 0)
        XCTAssertEqual(evaluation.state.bestCount, 5)
        XCTAssertNil(evaluation.state.lastQualifiedDay)
        XCTAssertFalse(evaluation.isQualifiedToday)
    }

    func testHistoryBackfillNoOverdueDayBecomesOverdueMidGapStillQualifies() {
        // Reminder becomes overdue at noon two days ago. Day -2 morning was clear, so day -2 qualifies.
        let twoDaysAgoNoon = hourOffset(12, from: dayOffset(-2))
        let state = StreakState(
            mode: .noOverdue,
            listID: "list-1",
            currentCount: 5,
            bestCount: 5,
            lastQualifiedDay: dayOffset(-3)
        )
        let history = StreakHistory(reminders: [
            StreakHistoryReminder(
                creationDate: dayOffset(-3),
                completionDate: hourOffset(13, from: dayOffset(-2)),
                dueDate: twoDaysAgoNoon,
                dueDateIncludesTime: true
            )
        ])

        let evaluation = engine.evaluate(state: state, listID: "list-1", history: history, now: now, calendar: calendar)

        XCTAssertEqual(evaluation.state.currentCount, 8)
        XCTAssertTrue(evaluation.isQualifiedToday)
    }

    func testHistoryBackfillNoOverdueBreaksOnFirstFullyOverdueGapDay() {
        // Reminder due at start of day -2, never completed. Day -2 is fully overdue all day -> fails.
        let state = StreakState(
            mode: .noOverdue,
            listID: "list-1",
            currentCount: 5,
            bestCount: 5,
            lastQualifiedDay: dayOffset(-3)
        )
        let history = StreakHistory(reminders: [
            StreakHistoryReminder(
                creationDate: dayOffset(-3),
                completionDate: nil,
                dueDate: dayOffset(-2),
                dueDateIncludesTime: true
            )
        ])

        let evaluation = engine.evaluate(state: state, listID: "list-1", history: history, now: now, calendar: calendar)

        XCTAssertEqual(evaluation.state.currentCount, 0)
        XCTAssertEqual(evaluation.state.bestCount, 5)
        XCTAssertNil(evaluation.state.lastQualifiedDay)
        XCTAssertFalse(evaluation.isQualifiedToday)
    }

    func testHistoryBackfillNoOverdueAllDayReminderDueTomorrowDoesntBlockToday() {
        let state = StreakState(
            mode: .noOverdue,
            listID: "list-1",
            currentCount: 1,
            bestCount: 1,
            lastQualifiedDay: dayOffset(-1)
        )
        let history = StreakHistory(reminders: [
            StreakHistoryReminder(
                creationDate: dayOffset(-1),
                completionDate: nil,
                dueDate: dayOffset(1),
                dueDateIncludesTime: false
            )
        ])

        let evaluation = engine.evaluate(state: state, listID: "list-1", history: history, now: now, calendar: calendar)

        XCTAssertEqual(evaluation.state.currentCount, 2)
        XCTAssertTrue(evaluation.isQualifiedToday)
    }

    func testHistoryBackfillRestartsStreakAfterMidWalkFailureAndPreservesPeak() {
        // Walk: day -3 empty -> qualifies (count climbs to 11),
        //       day -2 fully non-empty (R lives only on day -2) -> fails, count resets to 0,
        //       day -1 empty again -> restarts at 1.
        // Today empty -> 2. bestCount must reflect the mid-walk peak of 11.
        let state = StreakState(
            mode: .emptyList,
            listID: "list-1",
            currentCount: 10,
            bestCount: 10,
            lastQualifiedDay: dayOffset(-4)
        )
        let history = StreakHistory(reminders: [
            StreakHistoryReminder(creationDate: dayOffset(-2), completionDate: dayOffset(-1))
        ])

        let evaluation = engine.evaluate(state: state, listID: "list-1", history: history, now: now, calendar: calendar)

        XCTAssertEqual(evaluation.state.currentCount, 2)
        XCTAssertEqual(evaluation.state.bestCount, 11)
        XCTAssertTrue(evaluation.isQualifiedToday)
    }

    func testHistoryBackfillEmptyListWithMultipleOverlappingIntervals() {
        // Three reminders that together cover every moment of yesterday: streak must break.
        let yesterday = dayOffset(-1)
        let yesterdayNoon = hourOffset(12, from: yesterday)
        let yesterdayThreePM = hourOffset(15, from: yesterday)
        let state = StreakState(
            mode: .emptyList,
            listID: "list-1",
            currentCount: 1,
            bestCount: 1,
            lastQualifiedDay: dayOffset(-2)
        )
        let history = StreakHistory(reminders: [
            StreakHistoryReminder(creationDate: yesterday, completionDate: yesterdayThreePM),
            StreakHistoryReminder(creationDate: yesterdayNoon, completionDate: dayOffset(0)),
            StreakHistoryReminder(creationDate: yesterdayThreePM, completionDate: nil),
        ])

        let evaluation = engine.evaluate(state: state, listID: "list-1", history: history, now: now, calendar: calendar)

        XCTAssertEqual(evaluation.state.currentCount, 0)
        XCTAssertNil(evaluation.state.lastQualifiedDay)
        XCTAssertFalse(evaluation.isQualifiedToday)
    }

    func testHistoryBackfillNoOverdueIgnoresUndatedReminders() {
        let state = StreakState(
            mode: .noOverdue,
            listID: "list-1",
            currentCount: 1,
            bestCount: 1,
            lastQualifiedDay: dayOffset(-1)
        )
        let history = StreakHistory(reminders: [
            StreakHistoryReminder(creationDate: dayOffset(-2), completionDate: nil, dueDate: nil)
        ])

        let evaluation = engine.evaluate(state: state, listID: "list-1", history: history, now: now, calendar: calendar)

        XCTAssertEqual(evaluation.state.currentCount, 2)
        XCTAssertTrue(evaluation.isQualifiedToday)
    }

    func testHistoryNoOverdueAllDayReminderDueTodayNotOverdue() {
        let state = StreakState(
            mode: .noOverdue,
            listID: "list-1",
            currentCount: 1,
            bestCount: 1,
            lastQualifiedDay: dayOffset(-1)
        )
        let history = StreakHistory(reminders: [
            StreakHistoryReminder(
                creationDate: dayOffset(-1),
                completionDate: nil,
                dueDate: startOfDay(now),
                dueDateIncludesTime: false
            )
        ])

        let evaluation = engine.evaluate(state: state, listID: "list-1", history: history, now: now, calendar: calendar)

        XCTAssertEqual(evaluation.state.currentCount, 2)
        XCTAssertTrue(evaluation.isQualifiedToday)
    }

    func testHistoryEvaluateWithoutLastQualifiedDayDoesNoBackfill() {
        let state = StreakState(
            mode: .emptyList,
            listID: "list-1",
            currentCount: 0,
            bestCount: 5,
            lastQualifiedDay: nil
        )
        let history = StreakHistory(reminders: [])

        let evaluation = engine.evaluate(state: state, listID: "list-1", history: history, now: now, calendar: calendar)

        XCTAssertEqual(evaluation.state.currentCount, 1)
        XCTAssertEqual(evaluation.state.bestCount, 5)
        XCTAssertEqual(evaluation.state.lastQualifiedDay, startOfDay(now))
        XCTAssertTrue(evaluation.isQualifiedToday)
    }

    func testHistoryTodayQualifiesViaEarlierCompletionDespiteCurrentNonEmpty() {
        let earlierToday = hourOffset(5, from: startOfDay(now))
        let state = StreakState(
            mode: .dailyProgress,
            listID: "list-1",
            currentCount: 2,
            bestCount: 2,
            lastQualifiedDay: dayOffset(-1)
        )
        let history = StreakHistory(reminders: [
            StreakHistoryReminder(creationDate: dayOffset(-1), completionDate: earlierToday),
            StreakHistoryReminder(creationDate: earlierToday, completionDate: nil),
        ])

        let evaluation = engine.evaluate(state: state, listID: "list-1", history: history, now: now, calendar: calendar)

        XCTAssertEqual(evaluation.state.currentCount, 3)
        XCTAssertTrue(evaluation.isQualifiedToday)
    }

    func testHistoryTodayDoesNotQualifyEmptyListWhenCurrentlyNonEmpty() {
        // List briefly emptied earlier today (R1 completed at 4am) but a new reminder now
        // makes it non-empty. Today does NOT qualify under end-of-day semantics; the streak
        // count from yesterday is preserved via sticky.
        let fourAm = hourOffset(4, from: startOfDay(now))
        let sevenAm = hourOffset(7, from: startOfDay(now))
        let state = StreakState(
            mode: .emptyList,
            listID: "list-1",
            currentCount: 2,
            bestCount: 2,
            lastQualifiedDay: dayOffset(-1)
        )
        let history = StreakHistory(reminders: [
            StreakHistoryReminder(creationDate: dayOffset(-1), completionDate: fourAm),
            StreakHistoryReminder(creationDate: sevenAm, completionDate: nil),
        ])

        let evaluation = engine.evaluate(state: state, listID: "list-1", history: history, now: now, calendar: calendar)

        XCTAssertEqual(evaluation.state.currentCount, 2)
        XCTAssertEqual(evaluation.state.lastQualifiedDay, dayOffset(-1))
        XCTAssertFalse(evaluation.isQualifiedToday)
    }

    func testHistoryEvaluatePreservesBestCountAcrossListSwitch() {
        let state = StreakState(
            mode: .emptyList,
            listID: "list-1",
            currentCount: 4,
            bestCount: 9,
            lastQualifiedDay: dayOffset(-1)
        )
        let history = StreakHistory(reminders: [])

        let evaluation = engine.evaluate(state: state, listID: "list-2", history: history, now: now, calendar: calendar)

        XCTAssertEqual(evaluation.state.listID, "list-2")
        XCTAssertEqual(evaluation.state.currentCount, 1)
        XCTAssertEqual(evaluation.state.bestCount, 9)
    }

    func testHistoryBackfillRestartsStreakWhenLastQualifiedDayIsOlderThanCap() {
        // 45 days ago is past the 30-day walk cap, so even with empty history (list always empty)
        // the old streak doesn't connect to the new walk. Walk runs the last 30 days, restart-at-1
        // on the first walked day (its prev day != stored lastQualifiedDay), then climbs to 30.
        // Today extends to 31. bestCount preserves the old high.
        let cappedStart = calendar.date(byAdding: .day, value: -StreakEngine.walkLookbackDays, to: startOfDay(now))!
        let firstWalkedDay = cappedStart  // dayCursor = max(firstGapDay = -44, cap = -30) = -30
        // Sanity: 30 walked days from -30..<today plus today = 31.
        XCTAssertEqual(calendar.dateComponents([.day], from: firstWalkedDay, to: startOfDay(now)).day, 30)

        let state = StreakState(
            mode: .emptyList,
            listID: "list-1",
            currentCount: 100,
            bestCount: 100,
            lastQualifiedDay: dayOffset(-45)
        )
        let history = StreakHistory(reminders: [])

        let evaluation = engine.evaluate(state: state, listID: "list-1", history: history, now: now, calendar: calendar)

        XCTAssertEqual(evaluation.state.currentCount, 31)
        XCTAssertEqual(evaluation.state.bestCount, 100)
        XCTAssertEqual(evaluation.state.lastQualifiedDay, startOfDay(now))
        XCTAssertTrue(evaluation.isQualifiedToday)
    }

    func testHistoryBackfillContinuesStreakWhenLastQualifiedDayIsAtCapBoundary() {
        // Exactly cap days ago: walk cap = today - cap, lastQualifiedDay = today - cap.
        // firstGapDay = today - cap + 1. continuesStreak fires on first walked day, streak grows.
        let state = StreakState(
            mode: .emptyList,
            listID: "list-1",
            currentCount: 5,
            bestCount: 5,
            lastQualifiedDay: dayOffset(-StreakEngine.walkLookbackDays)
        )
        let history = StreakHistory(reminders: [])

        let evaluation = engine.evaluate(state: state, listID: "list-1", history: history, now: now, calendar: calendar)

        // 5 (base) + walkLookbackDays - 1 (walked days) + 1 (today) = 5 + walkLookbackDays
        XCTAssertEqual(evaluation.state.currentCount, 5 + StreakEngine.walkLookbackDays)
        XCTAssertTrue(evaluation.isQualifiedToday)
    }

    func testHistoryStickyPreservesStreakCountButFlagsTodayNotCurrentlyQualified() {
        // Day was already earned earlier today (lastQualifiedDay = today, count = 5). The user
        // then added a reminder so the list is currently non-empty. The streak count and
        // lastQualifiedDay must stay put (sticky preserves the earned day), but isQualifiedToday
        // flips to false so the UI label reflects current state.
        let earlierToday = hourOffset(8, from: startOfDay(now))
        let state = StreakState(
            mode: .emptyList,
            listID: "list-1",
            currentCount: 5,
            bestCount: 5,
            lastQualifiedDay: startOfDay(now)
        )
        let history = StreakHistory(reminders: [
            StreakHistoryReminder(creationDate: earlierToday, completionDate: nil)
        ])

        let evaluation = engine.evaluate(state: state, listID: "list-1", history: history, now: now, calendar: calendar)

        XCTAssertEqual(evaluation.state.currentCount, 5)
        XCTAssertEqual(evaluation.state.bestCount, 5)
        XCTAssertEqual(evaluation.state.lastQualifiedDay, startOfDay(now))
        XCTAssertFalse(evaluation.isQualifiedToday)
    }

    func testQualifiesOnDayDailyProgressFailsBothDaysWhenReminderRemainsIncomplete() {
        // Reminder created two days ago at noon, never completed. Under end-of-day semantics,
        // both gap days end with the list non-empty and no completion -> neither qualifies.
        let twoDaysAgoNoon = hourOffset(12, from: dayOffset(-2))
        let history = StreakHistory(reminders: [
            StreakHistoryReminder(creationDate: twoDaysAgoNoon, completionDate: nil)
        ])

        let yesterdayQualifies = engine.qualifiesOnDay(
            mode: .dailyProgress,
            history: history,
            dayWindow: dayOffset(-1)..<startOfDay(now),
            calendar: calendar
        )
        XCTAssertFalse(yesterdayQualifies)

        let twoDaysAgoQualifies = engine.qualifiesOnDay(
            mode: .dailyProgress,
            history: history,
            dayWindow: dayOffset(-2)..<dayOffset(-1),
            calendar: calendar
        )
        XCTAssertFalse(twoDaysAgoQualifies)
    }

    func testAvailableModesForTodayListReturnsOnlyNoOverdue() {
        XCTAssertEqual(StreakMode.availableModes(forListID: SelectedListStore.todayID), [.noOverdue])
    }

    func testAvailableModesForRegularListReturnsAllModes() {
        let modes = StreakMode.availableModes(forListID: "calendar-uuid")
        XCTAssertEqual(Set(modes), Set(StreakMode.allCases))
    }

    func testAvailableModesForNilListReturnsAllModes() {
        let modes = StreakMode.availableModes(forListID: nil)
        XCTAssertEqual(Set(modes), Set(StreakMode.allCases))
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
