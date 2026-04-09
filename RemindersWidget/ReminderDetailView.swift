import EventKit
import SwiftUI
import WidgetKit

struct ReminderDetailView: View {
    let listID: String
    let listTitle: String
    let listColor: Color
    let eventStore: EKEventStore
    @Binding var showSettings: Bool

    @State private var reminders: [ReminderItem] = []
    @State private var completingIDs: Set<String> = []
    @State private var fetchTask: Task<Void, Never>?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            header
            if reminders.isEmpty {
                Spacer()
                Text("No Reminders")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                reminderList
            }
        }
        .onAppear { fetchReminders() }
        .onChange(of: listID) { _, _ in
            reminders = []
            completingIDs = []
            fetchReminders()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                fetchReminders()
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    private var header: some View {
        HStack {
            Text(listTitle)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(listColor)
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var reminderList: some View {
        List {
            ForEach(reminders) { reminder in
                reminderRow(reminder)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .listStyle(.plain)
    }

    private func reminderRow(_ reminder: ReminderItem) -> some View {
        let isCompleting = completingIDs.contains(reminder.id)
        return Button {
            completeReminder(reminder)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isCompleting ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleting ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
                Text(reminder.title)
                    .strikethrough(isCompleting)
                    .foregroundStyle(isCompleting ? .secondary : .primary)
            }
        }
        .disabled(isCompleting)
    }

    private func completeReminder(_ reminder: ReminderItem) {
        guard let ekReminder = eventStore.calendarItem(withIdentifier: reminder.id) as? EKReminder else { return }
        ekReminder.isCompleted = true

        do {
            try eventStore.save(ekReminder, commit: true)
        } catch {
            ekReminder.isCompleted = false
            return
        }

        completingIDs.insert(reminder.id)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.4)) {
                reminders.removeAll { $0.id == reminder.id }
                completingIDs.remove(reminder.id)
            }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    @MainActor private func fetchReminders() {
        fetchTask?.cancel()
        fetchTask = Task {
            let ekReminders: [EKReminder]

            if listID == SelectedListStore.todayID {
                let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!
                let predicate = eventStore.predicateForIncompleteReminders(
                    withDueDateStarting: .distantPast,
                    ending: endOfDay,
                    calendars: nil
                )
                ekReminders = await withCheckedContinuation { (continuation: CheckedContinuation<[EKReminder], Never>) in
                    _ = eventStore.fetchReminders(matching: predicate) { reminders in
                        continuation.resume(returning: reminders ?? [])
                    }
                }
            } else {
                let calendars = eventStore.calendars(for: .reminder)
                guard let calendar = calendars.first(where: { $0.calendarIdentifier == listID }) else {
                    reminders = []
                    return
                }

                let predicate = eventStore.predicateForReminders(in: [calendar])
                ekReminders = await withCheckedContinuation { (continuation: CheckedContinuation<[EKReminder], Never>) in
                    _ = eventStore.fetchReminders(matching: predicate) { reminders in
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
                        calendarItemIdentifier: reminder.calendarItemIdentifier
                    )
                }

            guard !Task.isCancelled else { return }
            reminders = sortReminders(items)
        }
    }
}
