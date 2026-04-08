import WidgetKit
import EventKit

struct RemindersTimelineProvider: TimelineProvider {
    private let store = EKEventStore()

    func placeholder(in context: Context) -> ReminderEntry {
        ReminderEntry(
            date: Date(),
            reminders: [
                ReminderItem(title: "Reminder 1", dueDate: nil, creationDate: nil, externalID: nil),
                ReminderItem(title: "Reminder 2", dueDate: nil, creationDate: nil, externalID: nil),
                ReminderItem(title: "Reminder 3", dueDate: nil, creationDate: nil, externalID: nil),
            ],
            state: .configured
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ReminderEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        Task {
            let entry = await fetchEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReminderEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            let refreshDate = Date().addingTimeInterval(15 * 60)
            completion(Timeline(entries: [entry], policy: .after(refreshDate)))
        }
    }

    private func fetchEntry() async -> ReminderEntry {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        guard status == .fullAccess else {
            return ReminderEntry(date: Date(), reminders: [], state: .noAccess)
        }

        let listStore = SelectedListStore()
        guard let listID = listStore.selectedListID else {
            return ReminderEntry(date: Date(), reminders: [], state: .notConfigured)
        }

        let ekReminders: [EKReminder]

        if listID == SelectedListStore.todayID {
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
            guard let calendar = calendars.first(where: { $0.calendarIdentifier == listID }) else {
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
                    creationDate: reminder.creationDate,
                    externalID: reminder.calendarItemExternalIdentifier
                )
            }

        let sorted = Array(sortReminders(items).prefix(3))

        if sorted.isEmpty {
            return ReminderEntry(date: Date(), reminders: [], state: .empty)
        }

        return ReminderEntry(date: Date(), reminders: sorted, state: .configured)
    }
}
