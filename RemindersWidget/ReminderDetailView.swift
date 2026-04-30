import EventKit
import SwiftUI
import UIKit
import WidgetKit

struct ReminderDetailView: View {
    let listID: String
    let listTitle: String
    let listColor: Color
    let eventStore: EKEventStore
    @Binding var streakState: StreakState
    @Binding var showSettings: Bool

    @State private var reminders: [ReminderItem] = []
    @State private var completingIDs: Set<String> = []
    @State private var fetchTask: Task<Void, Never>?
    @State private var isStreakQualifiedToday = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            header
            streakSummary
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
            isStreakQualifiedToday = false
            fetchReminders()
        }
        .onChange(of: streakState.mode) { _, _ in
            // Goal change in settings resets streak state in the store; re-evaluate against
            // the current list contents so the banner doesn't show a stale 0-day streak when
            // the new mode trivially qualifies today (e.g. switched to Complete All on an
            // already-empty list).
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
                .lineLimit(1)
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

    private var streakSummary: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(streakState.currentCount)-day streak")
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(streakStatusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("Best")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text("\(streakState.bestCount) \(streakState.bestCount == 1 ? "day" : "days")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(listColor.opacity(0.10))
    }

    private var streakStatusMessage: String {
        if isStreakQualifiedToday {
            return "Streak extended for today."
        }

        switch streakState.mode {
        case .noOverdue:
            // Today already implies "due today or overdue", so "all overdue" reads as redundant
            // there. Phrase it the same as Complete All for the Today list.
            if listID == SelectedListStore.todayID {
                return "Complete all reminders today."
            }
            return "Complete all overdue reminders."
        case .dailyProgress:
            return "Complete a reminder today."
        case .emptyList:
            return "Complete all reminders today."
        }
    }

    private var reminderList: some View {
        List {
            Section {
                ForEach(reminders) { reminder in
                    reminderRow(reminder)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            Section {
                Button {
                    openRemindersApp()
                } label: {
                    HStack {
                        Text("Open Reminders")
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                    }
                    .foregroundStyle(.secondary)
                }
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
            fetchReminders()
        }
    }

    private func openRemindersApp() {
        if let url = URL(string: "x-apple-reminderkit://") {
            UIApplication.shared.open(url)
        }
    }

    @MainActor private func fetchReminders() {
        fetchTask?.cancel()
        fetchTask = Task {
            // Capture "now" once and thread it through the EventKit fetch and the streak
            // evaluation so they can't disagree about what "today" is — e.g. if the task
            // happens to span midnight or a timezone change.
            let now = Date()
            let storedState = StreakStore().state
            guard
                let result = await fetchReminderHistory(
                    now: now,
                    storedLastQualifiedDay: storedState.lastQualifiedDay
                )
            else {
                guard !Task.isCancelled else { return }
                reminders = []
                return
            }

            let items = result.incompleteReminders.map(\.reminderItem)
            // Currently-incomplete reminders without a creationDate (rare EventKit case) fall
            // back to start-of-today: visible to today's qualification check (since
            // `creationDate < now` holds for any non-midnight `now`), but invisible at the end
            // of any prior day (`creationDate < end_of_past_day` is false), so they don't
            // retroactively credit or break a backfilled day. Completed reminders almost always
            // supply completionDate; `.distantFuture` is the safety-net for the
            // (creation == nil && completion == nil) corrupt case, which would never happen for
            // a completed reminder anyway.
            let startOfToday = Calendar.current.startOfDay(for: now)
            let history = StreakHistory(
                reminders: result.incompleteReminders.map {
                    $0.streakHistoryReminder(creationDateFallback: startOfToday)
                }
                    + result.completedReminders.map {
                        $0.streakHistoryReminder(creationDateFallback: .distantFuture)
                    }
            )
            let evaluation = StreakEngine().evaluate(
                state: storedState,
                listID: listID,
                history: history,
                now: now
            )

            guard !Task.isCancelled else { return }
            reminders = sortReminders(items)
            var store = StreakStore()
            store.state = evaluation.state
            streakState = evaluation.state
            isStreakQualifiedToday = evaluation.isQualifiedToday
        }
    }

    private func fetchReminderHistory(now: Date, storedLastQualifiedDay: Date?) async -> ReminderFetchResult? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        // Match StreakEngine.walkLookbackDays so the fetch doesn't pull data the engine ignores.
        let lookbackCap =
            calendar.date(byAdding: .day, value: -StreakEngine.walkLookbackDays, to: startOfDay)
            ?? startOfDay
        let lookbackStart: Date = {
            guard let last = storedLastQualifiedDay, last < startOfDay else { return startOfDay }
            return max(calendar.startOfDay(for: last), lookbackCap)
        }()

        let selectedCalendars: [EKCalendar]?
        let incompletePredicate: NSPredicate

        if listID == SelectedListStore.todayID {
            selectedCalendars = nil
            incompletePredicate = eventStore.predicateForIncompleteReminders(
                withDueDateStarting: .distantPast,
                ending: endOfDay,
                calendars: nil
            )
        } else {
            let calendars = eventStore.calendars(for: .reminder)
            guard let selectedCalendar = calendars.first(where: { $0.calendarIdentifier == listID }) else {
                return nil
            }
            selectedCalendars = [selectedCalendar]
            incompletePredicate = eventStore.predicateForIncompleteReminders(
                withDueDateStarting: nil,
                ending: nil,
                calendars: selectedCalendars
            )
        }

        let incompleteReminders = await fetchReminders(matching: incompletePredicate)
        let completedPredicate = eventStore.predicateForCompletedReminders(
            withCompletionDateStarting: lookbackStart,
            ending: endOfDay,
            calendars: selectedCalendars
        )
        let completedReminders = await fetchReminders(matching: completedPredicate)

        return ReminderFetchResult(
            incompleteReminders: incompleteReminders,
            completedReminders: completedReminders
        )
    }

    private func fetchReminders(matching predicate: NSPredicate) async -> [EKReminder] {
        await withCheckedContinuation { (continuation: CheckedContinuation<[EKReminder], Never>) in
            _ = eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }
}

private struct ReminderFetchResult {
    let incompleteReminders: [EKReminder]
    let completedReminders: [EKReminder]
}
