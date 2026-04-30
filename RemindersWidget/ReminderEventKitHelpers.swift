import EventKit
import Foundation

extension EKReminder {
    var reminderItem: ReminderItem {
        ReminderItem(
            title: title ?? "",
            dueDate: dueDateComponents.flatMap { Calendar.current.date(from: $0) },
            dueDateIncludesTime: dueDateComponents?.hasTimeComponents ?? false,
            creationDate: creationDate,
            recurrence: hasRecurrenceRules
                ? recurrenceRules?.first.flatMap(ReminderRecurrence.init(rule:)) : nil,
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

}

private extension DateComponents {
    var hasTimeComponents: Bool {
        hour != nil || minute != nil || second != nil || nanosecond != nil
    }
}

extension ReminderRecurrence {
    init?(rule: EKRecurrenceRule) {
        // Anything beyond a plain frequency+interval — specific weekdays, months, ordinal
        // positions like "first Monday" — falls back to the generic "Repeats" label rather
        // than trying to reproduce Apple's full rule formatting.
        let isComplex =
            (rule.daysOfTheWeek?.isEmpty == false)
            || (rule.daysOfTheMonth?.isEmpty == false)
            || (rule.daysOfTheYear?.isEmpty == false)
            || (rule.weeksOfTheYear?.isEmpty == false)
            || (rule.monthsOfTheYear?.isEmpty == false)
            || (rule.setPositions?.isEmpty == false)

        if isComplex {
            self = .complex
            return
        }

        let frequency: Frequency
        switch rule.frequency {
        case .daily: frequency = .daily
        case .weekly: frequency = .weekly
        case .monthly: frequency = .monthly
        case .yearly: frequency = .yearly
        @unknown default:
            self = .complex
            return
        }

        self = .interval(frequency: frequency, count: max(1, rule.interval))
    }
}
