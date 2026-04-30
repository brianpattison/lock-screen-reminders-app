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
        let qualified = qualifies(mode: baseState.mode, snapshot: snapshot, now: now, calendar: calendar)

        guard qualified else {
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

        guard let lastQualifiedDay = baseState.lastQualifiedDay else {
            return qualifiedEvaluation(from: baseState, currentCount: 1, today: today)
        }

        if calendar.isDate(lastQualifiedDay, inSameDayAs: today) {
            return StreakEvaluation(state: baseState, isQualifiedToday: true)
        }

        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
        let currentCount: Int
        if let yesterday, calendar.isDate(lastQualifiedDay, inSameDayAs: yesterday) {
            currentCount = baseState.currentCount + 1
        } else {
            currentCount = 1
        }

        return qualifiedEvaluation(from: baseState, currentCount: currentCount, today: today)
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

    private func qualifiedEvaluation(from state: StreakState, currentCount: Int, today: Date) -> StreakEvaluation {
        StreakEvaluation(
            state: StreakState(
                mode: state.mode,
                listID: state.listID,
                currentCount: currentCount,
                bestCount: max(state.bestCount, currentCount),
                lastQualifiedDay: today
            ),
            isQualifiedToday: true
        )
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
