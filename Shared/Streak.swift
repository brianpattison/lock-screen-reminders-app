import Foundation

enum StreakMode: String, CaseIterable, Identifiable {
    case noOverdue
    case dailyProgress
    case emptyList

    var id: String { rawValue }

    var title: String {
        switch self {
        case .noOverdue:
            return "No Overdue"
        case .dailyProgress:
            return "Daily Progress"
        case .emptyList:
            return "Empty List"
        }
    }

    var description: String {
        switch self {
        case .noOverdue:
            return "Keep overdue reminders clear."
        case .dailyProgress:
            return "Complete one reminder, or keep the list empty."
        case .emptyList:
            return "Finish everything in the selected list."
        }
    }

    // The Today list is a synthetic cross-calendar view: list membership is implicit and
    // can't be reconstructed for past days. The Daily Progress and Empty List modes both
    // depend on per-day membership, so they're disabled for Today. No Overdue only depends
    // on each reminder's dueDate vs day boundary, which is well-defined cross-calendar.
    static func availableModes(forListID listID: String?) -> [StreakMode] {
        if listID == SelectedListStore.todayID {
            return [.noOverdue]
        }
        return StreakMode.allCases
    }
}

struct StreakReminder: Equatable {
    let dueDate: Date?
    let dueDateIncludesTime: Bool

    init(dueDate: Date?, dueDateIncludesTime: Bool = true) {
        self.dueDate = dueDate
        self.dueDateIncludesTime = dueDateIncludesTime
    }
}

struct StreakSnapshot: Equatable {
    let incompleteReminders: [StreakReminder]
    let completedTodayCount: Int

    init(incompleteReminders: [StreakReminder], completedTodayCount: Int = 0) {
        self.incompleteReminders = incompleteReminders
        self.completedTodayCount = completedTodayCount
    }
}

struct StreakHistoryReminder: Equatable {
    let creationDate: Date
    let completionDate: Date?
    let dueDate: Date?
    let dueDateIncludesTime: Bool

    init(
        creationDate: Date,
        completionDate: Date? = nil,
        dueDate: Date? = nil,
        dueDateIncludesTime: Bool = true
    ) {
        self.creationDate = creationDate
        self.completionDate = completionDate
        self.dueDate = dueDate
        self.dueDateIncludesTime = dueDateIncludesTime
    }
}

struct StreakHistory: Equatable {
    let reminders: [StreakHistoryReminder]

    init(reminders: [StreakHistoryReminder]) {
        self.reminders = reminders
    }
}

struct StreakState: Equatable {
    var mode: StreakMode
    var listID: String?
    var currentCount: Int
    var bestCount: Int
    var lastQualifiedDay: Date?

    static let empty = StreakState(
        mode: .noOverdue,
        listID: nil,
        currentCount: 0,
        bestCount: 0,
        lastQualifiedDay: nil
    )

    func reset(for listID: String?, mode: StreakMode? = nil) -> StreakState {
        StreakState(
            mode: mode ?? self.mode,
            listID: listID,
            currentCount: 0,
            bestCount: bestCount,
            lastQualifiedDay: nil
        )
    }
}

struct StreakEvaluation: Equatable {
    let state: StreakState
    let isQualifiedToday: Bool
}

struct StreakEngine {
    // History-based backfill walks at most this many days. Beyond this, EventKit data is
    // unreliable: deleted reminders are invisible, so a credited day might actually have
    // had outstanding work. Treating older gaps as broken trades a tiny bit of leniency
    // for reliable correctness on long-inactive users.
    static let walkLookbackDays: Int = 30

    func evaluate(
        state: StreakState,
        listID: String?,
        snapshot: StreakSnapshot,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> StreakEvaluation {
        let baseState = state.listID == listID ? state : state.reset(for: listID)
        let today = calendar.startOfDay(for: now)
        let qualifiedToday = qualifies(mode: baseState.mode, snapshot: snapshot, now: now, calendar: calendar)

        return finalize(
            baseState: baseState,
            listID: listID,
            runningCount: baseState.currentCount,
            runningLastQualified: baseState.lastQualifiedDay,
            qualifiedToday: qualifiedToday,
            today: today,
            calendar: calendar
        )
    }

    func evaluate(
        state: StreakState,
        listID: String?,
        history: StreakHistory,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> StreakEvaluation {
        let baseState = state.listID == listID ? state : state.reset(for: listID)
        let today = calendar.startOfDay(for: now)

        // Normalize stored lastQualifiedDay to today's calendar's start-of-day so the day-by-day
        // walk is stable across timezone changes and never starts mid-day. Clamp future values
        // (corrupt state) by treating them as missing.
        let normalizedLastQualified: Date? = baseState.lastQualifiedDay.flatMap { stored in
            let normalized = calendar.startOfDay(for: stored)
            return normalized > today ? nil : normalized
        }

        var runningCount = baseState.currentCount
        var runningLastQualified = normalizedLastQualified
        var peakBest = baseState.bestCount

        // Cap how far back the walk can reach. Beyond this, EventKit data is unreliable
        // for backfill: reminders the user deleted are gone, and a streak can be wrongly
        // credited from history we can no longer verify. If `lastQualifiedDay` is older
        // than the cap, the walk starts at the cap; the first walked day's continues-check
        // fails (prev day != lastQualifiedDay), restarting the streak count at 1.
        let walkStartCap = calendar.date(byAdding: .day, value: -Self.walkLookbackDays, to: today)

        if let last = normalizedLastQualified,
            let firstGapDay = calendar.date(byAdding: .day, value: 1, to: last)
        {
            var dayCursor = walkStartCap.map { max(firstGapDay, $0) } ?? firstGapDay
            while dayCursor < today {
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayCursor) else { break }
                let qualified = qualifiesOnDay(
                    mode: baseState.mode,
                    history: history,
                    dayWindow: dayCursor..<nextDay,
                    calendar: calendar
                )

                if qualified {
                    let prevDay = calendar.date(byAdding: .day, value: -1, to: dayCursor)
                    let continuesStreak: Bool = {
                        guard let prior = runningLastQualified, let prev = prevDay else { return false }
                        return calendar.isDate(prior, inSameDayAs: prev)
                    }()
                    runningCount = continuesStreak ? runningCount + 1 : 1
                    runningLastQualified = dayCursor
                    peakBest = max(peakBest, runningCount)
                } else {
                    runningCount = 0
                    runningLastQualified = nil
                }

                dayCursor = nextDay
            }
        }

        // Today's window is [start_of_today, now). Empty when now == start_of_today exactly.
        // The history path treats today as qualified if the criteria held at any moment so far,
        // which is more permissive than the snapshot path's "right now" check.
        let todayWindow = today..<max(today, now)
        let qualifiedToday = qualifiesOnDay(
            mode: baseState.mode,
            history: history,
            dayWindow: todayWindow,
            calendar: calendar
        )

        // Hoist any peak the walk discovered into baseState.bestCount so finalize preserves it
        // even when the walk failed mid-stream and runningCount is now smaller than the peak.
        let baseWithWalkPeak = StreakState(
            mode: baseState.mode,
            listID: baseState.listID,
            currentCount: baseState.currentCount,
            bestCount: peakBest,
            lastQualifiedDay: baseState.lastQualifiedDay
        )

        return finalize(
            baseState: baseWithWalkPeak,
            listID: listID,
            runningCount: runningCount,
            runningLastQualified: runningLastQualified,
            qualifiedToday: qualifiedToday,
            today: today,
            calendar: calendar
        )
    }

    func qualifies(
        mode: StreakMode,
        snapshot: StreakSnapshot,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        switch mode {
        case .noOverdue:
            return snapshot.incompleteReminders.allSatisfy { !isOverdue($0, now: now, calendar: calendar) }
        case .dailyProgress:
            return snapshot.completedTodayCount > 0 || snapshot.incompleteReminders.isEmpty
        case .emptyList:
            return snapshot.incompleteReminders.isEmpty
        }
    }

    // Qualification is point-in-time at the upper bound of the window:
    //   past day D -> moment is end_of_D (= start of D+1)
    //   today      -> moment is `now`
    // The check answers "is the goal met at this moment?" using strict `<` boundaries so a
    // reminder created or completed exactly at midnight belongs to the next day, not the prior one.
    func qualifiesOnDay(
        mode: StreakMode,
        history: StreakHistory,
        dayWindow: Range<Date>,
        calendar: Calendar = .current
    ) -> Bool {
        guard !dayWindow.isEmpty else { return false }
        let moment = dayWindow.upperBound
        switch mode {
        case .dailyProgress:
            if hasCompletion(in: dayWindow, history: history) {
                return true
            }
            return incompleteCount(at: moment, history: history) == 0
        case .emptyList:
            return incompleteCount(at: moment, history: history) == 0
        case .noOverdue:
            return overdueCount(at: moment, history: history, calendar: calendar) == 0
        }
    }

    private func finalize(
        baseState: StreakState,
        listID: String?,
        runningCount: Int,
        runningLastQualified: Date?,
        qualifiedToday: Bool,
        today: Date,
        calendar: Calendar
    ) -> StreakEvaluation {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
        let lastQualifiedToday =
            runningLastQualified
            .map { calendar.isDate($0, inSameDayAs: today) } ?? false
        let lastQualifiedYesterday: Bool = {
            guard let last = runningLastQualified, let yesterday else { return false }
            return calendar.isDate(last, inSameDayAs: yesterday)
        }()

        // `isQualifiedToday` reflects the live qualification check at `now` — it tracks the UI
        // "Today: Complete / Finish the list" label, which must match what the user currently
        // sees. The streak count and `lastQualifiedDay` are preserved separately via sticky
        // logic, so a day earned earlier stays in the streak history even if the user later
        // re-violates the goal.
        if !qualifiedToday {
            if lastQualifiedToday {
                return StreakEvaluation(
                    state: stateWith(
                        base: baseState, listID: listID, count: runningCount, lastQualified: runningLastQualified),
                    isQualifiedToday: false
                )
            }
            if lastQualifiedYesterday {
                return StreakEvaluation(
                    state: stateWith(
                        base: baseState, listID: listID, count: runningCount, lastQualified: runningLastQualified),
                    isQualifiedToday: false
                )
            }
            return StreakEvaluation(
                state: StreakState(
                    mode: baseState.mode,
                    listID: listID,
                    currentCount: 0,
                    bestCount: baseState.bestCount,
                    lastQualifiedDay: nil
                ),
                isQualifiedToday: false
            )
        }

        if lastQualifiedToday {
            return StreakEvaluation(
                state: stateWith(
                    base: baseState, listID: listID, count: runningCount, lastQualified: runningLastQualified),
                isQualifiedToday: true
            )
        }

        let newCount = lastQualifiedYesterday ? runningCount + 1 : 1
        return StreakEvaluation(
            state: stateWith(base: baseState, listID: listID, count: newCount, lastQualified: today),
            isQualifiedToday: true
        )
    }

    private func stateWith(base: StreakState, listID: String?, count: Int, lastQualified: Date?) -> StreakState {
        StreakState(
            mode: base.mode,
            listID: listID,
            currentCount: count,
            bestCount: max(base.bestCount, count),
            lastQualifiedDay: lastQualified
        )
    }

    private func hasCompletion(in window: Range<Date>, history: StreakHistory) -> Bool {
        guard !window.isEmpty else { return false }
        return history.reminders.contains { reminder in
            guard let completed = reminder.completionDate else { return false }
            return window.contains(completed)
        }
    }

    // Tests "state immediately before `moment`": creation strictly before, completion not yet
    // reached. A reminder created or completed at exactly `moment` is treated as belonging to
    // whatever day starts at `moment`, not the prior day.
    private func isInList(_ reminder: StreakHistoryReminder, at moment: Date) -> Bool {
        guard reminder.creationDate < moment else { return false }
        if let completed = reminder.completionDate, completed < moment {
            return false
        }
        return true
    }

    private func incompleteCount(at moment: Date, history: StreakHistory) -> Int {
        history.reminders.reduce(into: 0) { count, reminder in
            if isInList(reminder, at: moment) { count += 1 }
        }
    }

    private func overdueCount(at moment: Date, history: StreakHistory, calendar: Calendar) -> Int {
        history.reminders.reduce(into: 0) { count, reminder in
            guard isInList(reminder, at: moment), let dueDate = reminder.dueDate else { return }
            let threshold: Date
            if reminder.dueDateIncludesTime {
                threshold = dueDate
            } else {
                let dueStartOfDay = calendar.startOfDay(for: dueDate)
                threshold = calendar.date(byAdding: .day, value: 1, to: dueStartOfDay) ?? dueDate
            }
            if threshold < moment { count += 1 }
        }
    }

    private func isOverdue(_ reminder: StreakReminder, now: Date, calendar: Calendar) -> Bool {
        guard let dueDate = reminder.dueDate else { return false }

        if reminder.dueDateIncludesTime {
            return dueDate < now
        }

        return calendar.startOfDay(for: dueDate) < calendar.startOfDay(for: now)
    }
}

struct StreakStore {
    private static let suiteName = "group.com.brianpattison.RemindersWidget"
    private static let modeKey = "streakMode"
    private static let listIDKey = "streakListID"
    private static let currentCountKey = "streakCurrentCount"
    private static let bestCountKey = "streakBestCount"
    private static let lastQualifiedDayKey = "streakLastQualifiedDay"

    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = nil) {
        if let defaults {
            self.defaults = defaults
        } else if let shared = UserDefaults(suiteName: Self.suiteName) {
            self.defaults = shared
        } else {
            assertionFailure("Failed to create UserDefaults for App Group suite: \(Self.suiteName)")
            self.defaults = nil
        }
    }

    var state: StreakState {
        get {
            guard let defaults else { return .empty }
            let mode = defaults.string(forKey: Self.modeKey).flatMap(StreakMode.init(rawValue:)) ?? .noOverdue
            let lastQualifiedDay: Date?
            if defaults.object(forKey: Self.lastQualifiedDayKey) == nil {
                lastQualifiedDay = nil
            } else {
                lastQualifiedDay = Date(timeIntervalSince1970: defaults.double(forKey: Self.lastQualifiedDayKey))
            }

            return StreakState(
                mode: mode,
                listID: defaults.string(forKey: Self.listIDKey),
                currentCount: defaults.integer(forKey: Self.currentCountKey),
                bestCount: defaults.integer(forKey: Self.bestCountKey),
                lastQualifiedDay: lastQualifiedDay
            )
        }
        set {
            guard let defaults else { return }
            defaults.set(newValue.mode.rawValue, forKey: Self.modeKey)
            defaults.set(newValue.listID, forKey: Self.listIDKey)
            defaults.set(newValue.currentCount, forKey: Self.currentCountKey)
            defaults.set(newValue.bestCount, forKey: Self.bestCountKey)

            if let lastQualifiedDay = newValue.lastQualifiedDay {
                defaults.set(lastQualifiedDay.timeIntervalSince1970, forKey: Self.lastQualifiedDayKey)
            } else {
                defaults.removeObject(forKey: Self.lastQualifiedDayKey)
            }
        }
    }
}
