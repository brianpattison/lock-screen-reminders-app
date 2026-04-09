import EventKit
import SwiftUI
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

    private let eventStore = EKEventStore()

    var body: some View {
        Group {
            if authStatus == .fullAccess, let listID = selectedListID, let listTitle = selectedListTitle, let listColor = selectedListColor {
                ReminderDetailView(
                    listID: listID,
                    listTitle: listTitle,
                    listColor: listColor,
                    eventStore: eventStore,
                    showSettings: $showSettings
                )
            } else {
                emptyState
            }
        }
        .sheet(isPresented: $showSettings, onDismiss: loadSelectedList) {
            settingsSheet
        }
        .onAppear {
            authStatus = EKEventStore.authorizationStatus(for: .reminder)
            if authStatus == .fullAccess {
                loadLists()
                loadSelectedList()
            }
            if selectedListID == nil || authStatus != .fullAccess {
                showSettings = true
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
                Spacer()

                ReminderListIcon()

                Text("Lock Screen Reminders")
                    .font(.largeTitle)
                    .fontWeight(.bold)

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
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showSettings = false
                    }
                }
            }
        }
    }

    private var settingsMainView: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("WIDGET LIST")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Menu {
                    Button("Today") {
                        selectList(id: SelectedListStore.todayID, title: "Today", color: .blue)
                    }
                    ForEach(availableLists, id: \.id) { list in
                        Button(list.title) {
                            selectList(id: list.id, title: list.title, color: list.color)
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedListTitle ?? "Select a list")
                            .foregroundStyle(selectedListTitle != nil ? .primary : .secondary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .padding(12)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
                }
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
    }

    private var deniedView: some View {
        Text("Reminders access was denied. Go to **Settings \u{2192} Privacy & Security \u{2192} Reminders** and enable access for this app.")
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
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    private func selectList(id: String, title: String, color: Color) {
        selectedListID = id
        selectedListTitle = title
        selectedListColor = color

        var store = SelectedListStore()
        store.selectedListID = id
        store.selectedListTitle = title

        WidgetCenter.shared.reloadAllTimelines()
        fetchPreviewReminders()
    }

    @MainActor private func fetchPreviewReminders() {
        previewFetchTask?.cancel()
        guard let listID = selectedListID else { return }
        previewReminders = []

        previewFetchTask = Task {
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
                    previewReminders = []
                    return
                }

                let predicate = eventStore.predicateForIncompleteReminders(
                    withDueDateStarting: nil,
                    ending: nil,
                    calendars: [calendar]
                )
                ekReminders = await withCheckedContinuation { (continuation: CheckedContinuation<[EKReminder], Never>) in
                    _ = eventStore.fetchReminders(matching: predicate) { reminders in
                        continuation.resume(returning: reminders ?? [])
                    }
                }
            }

            let items = ekReminders
                .map { reminder in
                    ReminderItem(
                        title: reminder.title ?? "",
                        dueDate: reminder.dueDateComponents.flatMap { Calendar.current.date(from: $0) },
                        creationDate: reminder.creationDate,
                        calendarItemIdentifier: reminder.calendarItemIdentifier
                    )
                }

            guard !Task.isCancelled, selectedListID == listID else { return }
            previewReminders = Array(sortReminders(items).prefix(3))
        }
    }
}
