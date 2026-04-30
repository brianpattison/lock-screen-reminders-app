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

    func streakHistoryReminder(creationDateFallback fallbackDate: Date = Date()) -> StreakHistoryReminder {
        StreakHistoryReminder(
            creationDate: creationDate ?? completionDate ?? fallbackDate,
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
