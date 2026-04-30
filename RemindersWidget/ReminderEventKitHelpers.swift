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
    // for legacy/imported reminders). The caller chooses the last-resort fallback so the same
    // reminder can be invisible to past-day backfill (use `.distantFuture`) while still being
    // counted at "now" (use `startOfDay(now)`, which is < now for any non-midnight time but
    // >= the end of any past day, so it slots into the current snapshot only).
    func streakHistoryReminder(creationDateFallback fallbackDate: Date) -> StreakHistoryReminder {
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
