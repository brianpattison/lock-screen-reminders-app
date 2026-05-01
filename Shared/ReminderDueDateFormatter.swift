import Foundation

struct ReminderDueDateLabel: Equatable {
    let text: String
    let isOverdue: Bool
}

private enum DueDateBucket {
    case future
    case tomorrow
    case today
    case yesterday
    case past
}

func formatReminderDueDate(
    _ dueDate: Date,
    includesTime: Bool,
    now: Date,
    calendar: Calendar = .current,
    locale: Locale = .current
) -> ReminderDueDateLabel {
    let startOfToday = calendar.startOfDay(for: now)
    let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
    let startOfDayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: startOfToday)!
    let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!

    let bucket: DueDateBucket
    if dueDate >= startOfDayAfterTomorrow {
        bucket = .future
    } else if dueDate >= startOfTomorrow {
        bucket = .tomorrow
    } else if dueDate >= startOfToday {
        bucket = .today
    } else if dueDate >= startOfYesterday {
        bucket = .yesterday
    } else {
        bucket = .past
    }

    // A timed reminder due today flips to overdue once "now" passes the time. A date-only
    // reminder due today has the whole day, so it stays not-overdue regardless of clock time.
    let isOverdue: Bool
    switch bucket {
    case .past, .yesterday:
        isOverdue = true
    case .today:
        isOverdue = includesTime && dueDate < now
    case .tomorrow, .future:
        isOverdue = false
    }

    // Use the calendar's timezone for formatting too — otherwise the time component reflects
    // whatever the system timezone is, which can disagree with the day buckets we computed
    // above (a date "today at 6 AM" formatted in a different zone could read as a different
    // hour).
    let timeZone = calendar.timeZone
    let longDate = dueDate.formatted(
        Date.FormatStyle(
            date: .long, time: .omitted, locale: locale, calendar: calendar, timeZone: timeZone
        )
    )
    let longDateTime = dueDate.formatted(
        Date.FormatStyle(
            date: .long, time: .shortened, locale: locale, calendar: calendar, timeZone: timeZone
        )
    )
    let shortTime = dueDate.formatted(
        Date.FormatStyle(
            date: .omitted, time: .shortened, locale: locale, calendar: calendar, timeZone: timeZone
        )
    )

    let text: String
    switch bucket {
    case .future, .past:
        text = includesTime ? longDateTime : longDate
    case .tomorrow:
        text = includesTime ? "Tomorrow at \(shortTime)" : "Tomorrow"
    case .today:
        text = includesTime ? "Today at \(shortTime)" : "Today"
    case .yesterday:
        text = includesTime ? "Yesterday at \(shortTime)" : "Yesterday"
    }

    return ReminderDueDateLabel(text: text, isOverdue: isOverdue)
}
