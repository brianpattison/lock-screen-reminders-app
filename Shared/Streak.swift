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

        var runningCount = baseState.currentCount
        var runningLastQualified = baseState.lastQualifiedDay

        if let last = baseState.lastQualifiedDay,
           let firstGapDay = calendar.date(byAdding: .day, value: 1, to: last) {
            var dayCursor = firstGapDay
            while dayCursor < today {
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayCursor) else { break }
                let qualified = qualifiesOnDay(
                    mode: baseState.mode,
                    history: history,
                    dayStart: dayCursor,
                    dayEnd: nextDay,
                    calendar: calendar
                )

                if qualified {
                    let prevDay = calendar.date(byAdding: .day, value: -1, to: dayCursor)
                    let continues: Bool = {
                        guard let last = runningLastQualified, let prev = prevDay else { return false }
                        return calendar.isDate(last, inSameDayAs: prev)
                    }()
                    runningCount = continues ? runningCount + 1 : 1
                    runningLastQualified = dayCursor
                } else {
                    runningCount = 0
                    runningLastQualified = nil
                }

                dayCursor = nextDay
            }
        }

        let qualifiedToday = qualifiesOnDay(
            mode: baseState.mode,
            history: history,
            dayStart: today,
            dayEnd: max(today, now),
            calendar: calendar
        )

        return finalize(
            baseState: baseState,
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

    func qualifiesOnDay(
        mode: StreakMode,
        history: StreakHistory,
        dayStart: Date,
        dayEnd: Date,
        calendar: Calendar = .current
    ) -> Bool {
        switch mode {
        case .dailyProgress:
            if hasCompletion(in: dayStart, through: dayEnd, history: history) {
                return true
            }
            return hasUncoveredMoment(
                dayStart: dayStart,
                dayEnd: dayEnd,
                intervals: incompleteIntervals(history: history)
            )
        case .emptyList:
            return hasUncoveredMoment(
                dayStart: dayStart,
                dayEnd: dayEnd,
                intervals: incompleteIntervals(history: history)
            )
        case .noOverdue:
            return hasUncoveredMoment(
                dayStart: dayStart,
                dayEnd: dayEnd,
                intervals: overdueIntervals(history: history, calendar: calendar)
            )
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
        let lastQualifiedToday = runningLastQualified
            .map { calendar.isDate($0, inSameDayAs: today) } ?? false
        let lastQualifiedYesterday: Bool = {
            guard let last = runningLastQualified, let yesterday else { return false }
            return calendar.isDate(last, inSameDayAs: yesterday)
        }()

        if !qualifiedToday {
            if lastQualifiedToday {
                return StreakEvaluation(
                    state: stateWith(base: baseState, listID: listID, count: runningCount, lastQualified: runningLastQualified),
                    isQualifiedToday: true
                )
            }
            if lastQualifiedYesterday {
                return StreakEvaluation(
                    state: stateWith(base: baseState, listID: listID, count: runningCount, lastQualified: runningLastQualified),
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
                state: stateWith(base: baseState, listID: listID, count: runningCount, lastQualified: runningLastQualified),
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

    private func hasCompletion(in start: Date, through end: Date, history: StreakHistory) -> Bool {
        history.reminders.contains { reminder in
            guard let completed = reminder.completionDate else { return false }
            return completed >= start && completed < end
        }
    }

    private func incompleteIntervals(history: StreakHistory) -> [(start: Date, end: Date)] {
        history.reminders.map { reminder in
            (start: reminder.creationDate, end: reminder.completionDate ?? .distantFuture)
        }
    }

    private func overdueIntervals(history: StreakHistory, calendar: Calendar) -> [(start: Date, end: Date)] {
        history.reminders.compactMap { reminder -> (start: Date, end: Date)? in
            guard let dueDate = reminder.dueDate else { return nil }
            let threshold: Date
            if reminder.dueDateIncludesTime {
                threshold = dueDate
            } else {
                let dueStartOfDay = calendar.startOfDay(for: dueDate)
                threshold = calendar.date(byAdding: .day, value: 1, to: dueStartOfDay) ?? dueDate
            }
            let start = max(reminder.creationDate, threshold)
            let end = reminder.completionDate ?? .distantFuture
            guard start < end else { return nil }
            return (start: start, end: end)
        }
    }

    private func hasUncoveredMoment(
        dayStart: Date,
        dayEnd: Date,
        intervals: [(start: Date, end: Date)]
    ) -> Bool {
        guard dayStart < dayEnd else { return false }

        let relevant = intervals.filter { $0.start < dayEnd && $0.end > dayStart }
        if relevant.isEmpty { return true }

        let sorted = relevant.sorted { $0.start < $1.start }
        var coverage = dayStart
        for interval in sorted {
            if interval.start > coverage {
                return true
            }
            coverage = max(coverage, interval.end)
            if coverage >= dayEnd {
                return false
            }
        }
        return coverage < dayEnd
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
