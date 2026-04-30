import EventKit
import SwiftUI
#if DEBUG
import UIKit
#endif
import WidgetKit

struct ContentView: View {
    @State private var authStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
    @State private var selectedListID: String?
    @State private var selectedListTitle: String?
    @State private var selectedListColor: Color?
    @State private var availableLists: [(id: String, title: String, color: Color)] = []
    @State private var showSettings = false
    @State private var previewReminders: [ReminderItem] = []
    @State private var previewFetchTask: Task<Void, Never>?
#if DEBUG
    @State private var screenshotSeedTask: Task<Void, Never>?
#endif
    @State private var streakState: StreakState = .empty
    @State private var pendingStreakChange: PendingStreakChange?
    @State private var showStreakResetConfirmation = false
    @Environment(\.scenePhase) private var scenePhase

    private let eventStore = EKEventStore()

    var body: some View {
        Group {
            if authStatus == .fullAccess, let listID = selectedListID, let listTitle = selectedListTitle,
                let listColor = selectedListColor
            {
                ReminderDetailView(
                    listID: listID,
                    listTitle: listTitle,
                    listColor: listColor,
                    eventStore: eventStore,
                    streakState: $streakState,
                    showSettings: $showSettings
                )
            } else {
                emptyState
            }
        }
        .sheet(
            isPresented: $showSettings,
            onDismiss: {
                pendingStreakChange = nil
                showStreakResetConfirmation = false
                loadSelectedList()
                loadStreakState()
            }
        ) {
            settingsSheet
        }
        .onAppear {
#if DEBUG
            if shouldSeedScreenshots {
                seedScreenshotData()
                return
            }
#endif
            authStatus = EKEventStore.authorizationStatus(for: .reminder)
            loadStreakState()
            if authStatus == .fullAccess {
                loadLists()
                loadSelectedList()
            }
            if selectedListID == nil || authStatus != .fullAccess {
                showSettings = true
            }
#if DEBUG
            if shouldShowSettingsForScreenshots {
                showSettings = true
            }
#endif
        }
        .onChange(of: scenePhase) { _, newPhase in
            // The user can grant Reminders access from system Settings while we're backgrounded.
            // Re-read auth status and reload list state on return so the denied/request UI
            // doesn't stay stuck until the next app launch.
            guard newPhase == .active else { return }
            authStatus = EKEventStore.authorizationStatus(for: .reminder)
            loadStreakState()
            if authStatus == .fullAccess {
                loadLists()
                loadSelectedList()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            HStack {
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

            Spacer()
            Image(systemName: "checklist")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
                .padding(.bottom, 24)
            Text("Lock Screen Reminders")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 24)
            Text("Tap the gear icon to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
    }

    // MARK: - Settings Sheet

    private var settingsSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Group {
                    switch authStatus {
                    case .fullAccess:
                        settingsMainView
                    case .denied, .restricted:
                        deniedView
                    default:
                        requestAccessView
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showSettings = false
                    }
                }
            }
            .alert("Reset streak?", isPresented: $showStreakResetConfirmation) {
                Button("Cancel", role: .cancel) {
                    pendingStreakChange = nil
                }
                Button("Reset", role: .destructive) {
                    applyPendingStreakChange()
                }
            } message: {
                Text("Changing the widget list or streak goal starts a new streak.")
            }
        }
    }

    private var settingsMainView: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("WIDGET LIST")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                NavigationLink {
                    WidgetListSelectionView(
                        lists: availableLists,
                        selectedListID: selectedListID,
                        onSelect: requestListSelection
                    )
                } label: {
                    selectionLinkLabel(
                        title: selectedListTitle ?? "Select a list",
                        subtitle: selectedListTitle == nil
                            ? "Choose what appears in the widget." : "Used by the app and widget.",
                        isPlaceholder: selectedListTitle == nil
                    )
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text("STREAK GOAL")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                NavigationLink {
                    StreakGoalSelectionView(
                        availableModes: StreakMode.availableModes(forListID: selectedListID),
                        selectedMode: streakState.mode,
                        onSelect: requestStreakModeSelection
                    )
                } label: {
                    selectionLinkLabel(
                        title: streakState.mode.title,
                        subtitle: streakState.mode.description,
                        isPlaceholder: false
                    )
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if selectedListID != nil {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WIDGET PREVIEW")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if previewReminders.isEmpty {
                        Text("No reminders")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color(white: 0.25), in: RoundedRectangle(cornerRadius: 16))
                    } else {
                        ReminderListView(reminders: previewReminders)
                            .foregroundStyle(.white)
                            .padding(16)
                            .background(Color(white: 0.25), in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .frame(maxWidth: 200, alignment: .leading)
            }

            Text("Long press your Lock Screen, tap **Customize**, then add the **Reminders** widget below the clock.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.leading)
        .onAppear { fetchPreviewReminders() }
    }

    private func selectionLinkLabel(title: String, subtitle: String, isPlaceholder: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(isPlaceholder ? .secondary : .primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
    }

    private var deniedView: some View {
        Text(
            "Reminders access was denied. Go to **Settings \u{2192} Privacy & Security \u{2192} Reminders** and enable access for this app."
        )
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var requestAccessView: some View {
        VStack(spacing: 12) {
            Text("This app displays your reminders on the Lock Screen. Grant access to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Continue") {
                Task {
                    _ = try? await eventStore.requestFullAccessToReminders()
                    authStatus = EKEventStore.authorizationStatus(for: .reminder)
                    if authStatus == .fullAccess {
                        loadLists()
                        loadSelectedList()
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Data

    private func loadLists() {
        availableLists = eventStore.calendars(for: .reminder)
            .map { (id: $0.calendarIdentifier, title: $0.title, color: Color(cgColor: $0.cgColor)) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private func loadStreakState() {
        streakState = StreakStore().state
    }

    private func loadSelectedList() {
        let store = SelectedListStore()
        selectedListID = store.selectedListID

        if let listID = selectedListID {
            if listID == SelectedListStore.todayID {
                selectedListTitle = "Today"
                selectedListColor = .blue
                fetchPreviewReminders()
            } else if let list = availableLists.first(where: { $0.id == listID }) {
                selectedListTitle = list.title
                selectedListColor = list.color
                fetchPreviewReminders()
            } else {
                // Stored list no longer exists
                selectedListID = nil
                selectedListTitle = nil
                selectedListColor = nil
                var mutableStore = SelectedListStore()
                mutableStore.selectedListID = nil
                mutableStore.selectedListTitle = nil
                resetStreak(for: nil)
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    private func requestListSelection(id: String, title: String, color: Color) {
        guard selectedListID != id else { return }

        if streakState.currentCount > 0 {
            pendingStreakChange = .list(id: id, title: title, color: color)
            showStreakResetConfirmation = true
        } else {
            applyListSelection(id: id, title: title, color: color)
        }
    }

    private func applyListSelection(id: String, title: String, color: Color) {
        selectedListID = id
        selectedListTitle = title
        selectedListColor = color

        var store = SelectedListStore()
        store.selectedListID = id
        store.selectedListTitle = title

        resetStreak(for: id)

        WidgetCenter.shared.reloadAllTimelines()
        fetchPreviewReminders()
    }

    private func requestStreakModeSelection(_ mode: StreakMode) {
        guard streakState.mode != mode else { return }

        if streakState.currentCount > 0 {
            pendingStreakChange = .mode(mode)
            showStreakResetConfirmation = true
        } else {
            applyStreakModeSelection(mode)
        }
    }

    private func applyStreakModeSelection(_ mode: StreakMode) {
        let resetState = StreakStore().state.reset(for: selectedListID, mode: mode)
        var store = StreakStore()
        store.state = resetState
        streakState = resetState
    }

    private func resetStreak(for listID: String?) {
        // Today list only supports No Overdue (see StreakMode.availableModes). When switching
        // to Today, force the mode regardless of what was previously selected; switching away
        // from Today leaves the mode at No Overdue, which the user can change via the picker.
        let availableModes = StreakMode.availableModes(forListID: listID)
        let modeOverride: StreakMode? = availableModes.contains(streakState.mode) ? nil : availableModes.first
        let resetState = StreakStore().state.reset(for: listID, mode: modeOverride)
        var store = StreakStore()
        store.state = resetState
        streakState = resetState
    }

    private func applyPendingStreakChange() {
        guard let pendingStreakChange else { return }

        switch pendingStreakChange {
        case let .list(id, title, color):
            applyListSelection(id: id, title: title, color: color)
        case let .mode(mode):
            applyStreakModeSelection(mode)
        }

        self.pendingStreakChange = nil
    }

    @MainActor private func fetchPreviewReminders() {
        previewFetchTask?.cancel()
        guard let listID = selectedListID else { return }
        previewReminders = []

        previewFetchTask = Task {
            let ekReminders: [EKReminder]

            if listID == SelectedListStore.todayID {
                let endOfDay = Calendar.current.date(
                    byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!
                let predicate = eventStore.predicateForIncompleteReminders(
                    withDueDateStarting: .distantPast,
                    ending: endOfDay,
                    calendars: nil
                )
                ekReminders = await withCheckedContinuation {
                    (continuation: CheckedContinuation<[EKReminder], Never>) in
                    _ = eventStore.fetchReminders(matching: predicate) { reminders in
                        continuation.resume(returning: reminders ?? [])
                    }
                }
            } else {
                let calendars = eventStore.calendars(for: .reminder)
                guard let calendar = calendars.first(where: { $0.calendarIdentifier == listID }) else {
                    previewReminders = []
                    return
                }

                let predicate = eventStore.predicateForIncompleteReminders(
                    withDueDateStarting: nil,
                    ending: nil,
                    calendars: [calendar]
                )
                ekReminders = await withCheckedContinuation {
                    (continuation: CheckedContinuation<[EKReminder], Never>) in
                    _ = eventStore.fetchReminders(matching: predicate) { reminders in
                        continuation.resume(returning: reminders ?? [])
                    }
                }
            }

            let items =
                ekReminders
                .map(\.reminderItem)

            guard !Task.isCancelled, selectedListID == listID else { return }
            previewReminders = Array(sortReminders(items).prefix(3))
        }
    }

#if DEBUG
    private var shouldSeedScreenshots: Bool {
        ProcessInfo.processInfo.arguments.contains("--seed-screenshots")
    }

    private var shouldShowSettingsForScreenshots: Bool {
        ProcessInfo.processInfo.arguments.contains("--show-settings-screenshot")
    }

    @MainActor private func seedScreenshotData() {
        guard screenshotSeedTask == nil else { return }

        screenshotSeedTask = Task { @MainActor in
            do {
                authStatus = try await ScreenshotSeed.run(eventStore: eventStore)
                loadStreakState()
                loadLists()
                loadSelectedList()
                showSettings = shouldShowSettingsForScreenshots
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                authStatus = EKEventStore.authorizationStatus(for: .reminder)
                if authStatus == .fullAccess {
                    loadLists()
                    loadSelectedList()
                }
                showSettings = selectedListID == nil || authStatus != .fullAccess
            }

            screenshotSeedTask = nil
        }
    }
#endif
}

private enum PendingStreakChange {
    case list(id: String, title: String, color: Color)
    case mode(StreakMode)
}

#if DEBUG
private enum ScreenshotSeed {
    private static let listTitle = "Daily Routine"
    private static let reminderTitles = ["Take vitamins", "Walk 10 minutes", "Read 10 pages"]

    enum SeedError: Error {
        case remindersAccessUnavailable
        case missingReminderSource
    }

    @MainActor static func run(eventStore: EKEventStore) async throws -> EKAuthorizationStatus {
        var status = EKEventStore.authorizationStatus(for: .reminder)
        if status != .fullAccess {
            _ = try? await eventStore.requestFullAccessToReminders()
            status = EKEventStore.authorizationStatus(for: .reminder)
        }
        guard status == .fullAccess else { throw SeedError.remindersAccessUnavailable }

        let calendar = try ensureCalendar(in: eventStore)
        let existing = await fetchReminders(in: calendar, eventStore: eventStore)
        for reminder in existing where reminderTitles.contains(reminder.title ?? "") {
            try eventStore.remove(reminder, commit: true)
        }

        for title in reminderTitles {
            let reminder = EKReminder(eventStore: eventStore)
            reminder.title = title
            reminder.calendar = calendar

            var dueDate = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            dueDate.calendar = Calendar.current
            reminder.dueDateComponents = dueDate

            let recurrence = EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil)
            reminder.addRecurrenceRule(recurrence)

            try eventStore.save(reminder, commit: true)
        }

        var selectedListStore = SelectedListStore()
        selectedListStore.selectedListID = calendar.calendarIdentifier
        selectedListStore.selectedListTitle = calendar.title

        var streakStore = StreakStore()
        let yesterday = Calendar.current.date(
            byAdding: .day,
            value: -1,
            to: Calendar.current.startOfDay(for: Date())
        )
        streakStore.state = StreakState(
            mode: .emptyList,
            listID: calendar.calendarIdentifier,
            currentCount: 7,
            bestCount: 12,
            lastQualifiedDay: yesterday
        )

        UserDefaults(suiteName: "group.com.brianpattison.RemindersWidget")?.synchronize()
        return status
    }

    @MainActor private static func ensureCalendar(in eventStore: EKEventStore) throws -> EKCalendar {
        if let calendar = eventStore.calendars(for: .reminder)
            .first(where: { $0.title == listTitle && $0.allowsContentModifications })
        {
            return calendar
        }

        guard let source = eventStore.defaultCalendarForNewReminders()?.source
            ?? eventStore.sources.first(where: { $0.sourceType == .local })
            ?? eventStore.sources.first
        else {
            throw SeedError.missingReminderSource
        }

        let calendar = EKCalendar(for: .reminder, eventStore: eventStore)
        calendar.title = listTitle
        calendar.cgColor = UIColor.systemBlue.cgColor
        calendar.source = source
        try eventStore.saveCalendar(calendar, commit: true)
        return calendar
    }

    @MainActor private static func fetchReminders(in calendar: EKCalendar, eventStore: EKEventStore) async -> [EKReminder] {
        let predicate = eventStore.predicateForReminders(in: [calendar])
        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }
}
#endif

private struct WidgetListSelectionView: View {
    let lists: [(id: String, title: String, color: Color)]
    let selectedListID: String?
    let onSelect: (String, String, Color) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                listButton(id: SelectedListStore.todayID, title: "Today", color: .blue)
                ForEach(lists, id: \.id) { list in
                    listButton(id: list.id, title: list.title, color: list.color)
                }
            } footer: {
                Text("The selected list appears in the app, widget preview, and Lock Screen widget.")
            }
        }
        .navigationTitle("Widget List")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func listButton(id: String, title: String, color: Color) -> some View {
        Button {
            onSelect(id, title, color)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                if selectedListID == id {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
        }
    }
}

private struct StreakGoalSelectionView: View {
    let availableModes: [StreakMode]
    let selectedMode: StreakMode
    let onSelect: (StreakMode) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                ForEach(availableModes) { mode in
                    Button {
                        onSelect(mode)
                        dismiss()
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(mode.title)
                                    .foregroundStyle(.primary)
                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
            } footer: {
                Text("Changing the goal resets the current streak after confirmation.")
            }
        }
        .navigationTitle("Streak Goal")
        .navigationBarTitleDisplayMode(.inline)
    }
}
