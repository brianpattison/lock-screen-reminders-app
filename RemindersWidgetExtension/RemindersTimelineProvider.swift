import WidgetKit
import EventKit

struct RemindersTimelineProvider: AppIntentTimelineProvider {
    private let store = EKEventStore()

    func placeholder(in context: Context) -> ReminderEntry {
        ReminderEntry(
            date: Date(),
            reminders: [
                ReminderItem(title: "Reminder 1", dueDate: nil, creationDate: nil),
                ReminderItem(title: "Reminder 2", dueDate: nil, creationDate: nil),
                ReminderItem(title: "Reminder 3", dueDate: nil, creationDate: nil),
            ],
            state: .configured
        )
    }

    func snapshot(for configuration: SelectListIntent, in context: Context) async -> ReminderEntry {
        if context.isPreview {
            return placeholder(in: context)
        }
        return await fetchEntry(for: configuration)
    }

    func timeline(for configuration: SelectListIntent, in context: Context) async -> Timeline<ReminderEntry> {
        let entry = await fetchEntry(for: configuration)
        let refreshDate = Date().addingTimeInterval(15 * 60)
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }

    private func fetchEntry(for configuration: SelectListIntent) async -> ReminderEntry {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        guard status == .fullAccess else {
            return ReminderEntry(date: Date(), reminders: [], state: .noAccess)
        }

        guard let listEntity = configuration.reminderList else {
            return ReminderEntry(date: Date(), reminders: [], state: .notConfigured)
        }

        let ekReminders: [EKReminder]

        if listEntity.isToday {
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!
            let predicate = store.predicateForIncompleteReminders(
                withDueDateStarting: .distantPast,
                ending: endOfDay,
                calendars: nil
            )
            ekReminders = await withCheckedContinuation { (continuation: CheckedContinuation<[EKReminder], Never>) in
                _ = store.fetchReminders(matching: predicate) { reminders in
                    continuation.resume(returning: reminders ?? [])
                }
            }
        } else {
            let calendars = store.calendars(for: .reminder)
            guard let calendar = calendars.first(where: { $0.calendarIdentifier == listEntity.id }) else {
                return ReminderEntry(date: Date(), reminders: [], state: .notConfigured)
            }

            let predicate = store.predicateForReminders(in: [calendar])
            ekReminders = await withCheckedContinuation { (continuation: CheckedContinuation<[EKReminder], Never>) in
                _ = store.fetchReminders(matching: predicate) { reminders in
                    continuation.resume(returning: reminders ?? [])
                }
            }
        }

        let items = ekReminders
            .filter { !$0.isCompleted }
            .map { reminder in
                ReminderItem(
                    title: reminder.title ?? "",
                    dueDate: reminder.dueDateComponents.flatMap { Calendar.current.date(from: $0) },
                    creationDate: reminder.creationDate
                )
            }

        let sorted = Array(sortReminders(items).prefix(3))

        if sorted.isEmpty {
            return ReminderEntry(date: Date(), reminders: [], state: .empty)
        }

        return ReminderEntry(date: Date(), reminders: sorted, state: .configured)
    }
}
