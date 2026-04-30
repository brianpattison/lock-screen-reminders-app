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
                Text(streakStatusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("Best")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("\(streakState.bestCount) \(streakState.bestCount == 1 ? "day" : "days")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
            return "Clear overdue reminders to keep the streak."
        case .dailyProgress:
            return "Complete a reminder to keep the streak."
        case .emptyList:
            return "Finish everything to keep the streak."
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
            let storedState = StreakStore().state
            guard let result = await fetchReminderHistory(storedLastQualifiedDay: storedState.lastQualifiedDay) else {
                guard !Task.isCancelled else { return }
                reminders = []
                return
            }

            let items = result.incompleteReminders.map(\.reminderItem)
            let evaluation: StreakEvaluation

            if listID == SelectedListStore.todayID {
                let snapshot = StreakSnapshot(
                    incompleteReminders: result.incompleteReminders.map(\.streakReminder),
                    completedTodayCount: result.completedTodayInScopeCount
                )
                evaluation = StreakEngine().evaluate(
                    state: storedState,
                    listID: listID,
                    snapshot: snapshot
                )
            } else {
                let history = StreakHistory(
                    reminders: result.incompleteReminders.map {
                        $0.streakHistoryReminder(creationDateFallback: result.historyCreationFallback)
                    }
                        + result.completedReminders.map {
                            $0.streakHistoryReminder(creationDateFallback: result.historyCreationFallback)
                        }
                )
                evaluation = StreakEngine().evaluate(
                    state: storedState,
                    listID: listID,
                    history: history
                )
            }

            guard !Task.isCancelled else { return }
            reminders = sortReminders(items)
            var store = StreakStore()
            store.state = evaluation.state
            streakState = evaluation.state
            isStreakQualifiedToday = evaluation.isQualifiedToday
        }
    }

    private func fetchReminderHistory(storedLastQualifiedDay: Date?) async -> ReminderFetchResult? {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let lookbackStart: Date = {
            guard let last = storedLastQualifiedDay, last < startOfDay else { return startOfDay }
            return last
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

        let completedTodayInScopeCount: Int = {
            let todayCompletions = completedReminders.filter { reminder in
                guard let completionDate = reminder.completionDate else { return false }
                return completionDate >= startOfDay && completionDate < endOfDay
            }
            if listID == SelectedListStore.todayID {
                return todayCompletions.filter { $0.isInTodayScope(endingAt: endOfDay) }.count
            }
            return todayCompletions.count
        }()

        return ReminderFetchResult(
            incompleteReminders: incompleteReminders,
            completedReminders: completedReminders,
            historyCreationFallback: lookbackStart,
            completedTodayInScopeCount: completedTodayInScopeCount
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
    let historyCreationFallback: Date
    let completedTodayInScopeCount: Int
}
