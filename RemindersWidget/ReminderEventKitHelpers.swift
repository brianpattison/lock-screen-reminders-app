import EventKit
import Foundation

extension EKReminder {
    var reminderItem: ReminderItem {
        ReminderItem(
            title: title ?? "",
            dueDate: dueDateComponents.flatMap { Calendar.current.date(from: $0) },
            creationDate: creationDate,
            calendarItemIdentifier: calendarItemIdentifier
        )
    }

    var streakReminder: StreakReminder {
        StreakReminder(
            dueDate: dueDateComponents.flatMap { Calendar.current.date(from: $0) },
            dueDateIncludesTime: dueDateComponents?.hasTimeComponents ?? true
        )
    }

    // Falls back to `completionDate` when EventKit reports no creation date (rare but possible
    // for legacy/imported reminders). If both are nil, `.distantFuture` makes the reminder
    // invisible to backfill — `isInList(_:at:)` requires `creationDate < moment`, so a
    // distant-future creation never registers as existing on any past day. Better to drop
    // the reminder than to spuriously break a No Overdue streak.
    var streakHistoryReminder: StreakHistoryReminder {
        StreakHistoryReminder(
            creationDate: creationDate ?? completionDate ?? .distantFuture,
            completionDate: completionDate,
            dueDate: dueDateComponents.flatMap { Calendar.current.date(from: $0) },
            dueDateIncludesTime: dueDateComponents?.hasTimeComponents ?? true
        )
    }

    func isInTodayScope(endingAt endOfDay: Date, calendar: Calendar = .current) -> Bool {
        guard let dueDate = dueDateComponents.flatMap({ calendar.date(from: $0) }) else { return false }
        return dueDate < endOfDay
    }
}

private extension DateComponents {
    var hasTimeComponents: Bool {
        hour != nil || minute != nil || second != nil || nanosecond != nil
    }
}
