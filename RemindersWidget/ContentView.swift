import EventKit
import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var authStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
    @State private var selectedListID: String?
    @State private var selectedListTitle: String?
    @State private var availableLists: [(id: String, title: String)] = []
    @State private var reminders: [ReminderItem] = []

    private let eventStore = EKEventStore()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checklist")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("Lock Screen Reminders")
                .font(.largeTitle)
                .fontWeight(.bold)

            Group {
                switch authStatus {
                case .fullAccess:
                    mainView
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
        .onAppear {
            authStatus = EKEventStore.authorizationStatus(for: .reminder)
            if authStatus == .fullAccess {
                loadLists()
                loadSelectedList()
            }
        }
    }

    private var mainView: some View {
        VStack(spacing: 20) {
            // List picker
            VStack(alignment: .leading, spacing: 4) {
                Text("WIDGET LIST")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Menu {
                    Button("Today") {
                        selectList(id: SelectedListStore.todayID, title: "Today")
                    }
                    ForEach(availableLists, id: \.id) { list in
                        Button(list.title) {
                            selectList(id: list.id, title: list.title)
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

            // Widget preview
            if selectedListID != nil {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WIDGET PREVIEW")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if reminders.isEmpty {
                        Text("No reminders")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 16))
                    } else {
                        ReminderListView(reminders: reminders)
                            .padding(16)
                            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Setup instructions
            Text("Long press your Lock Screen, tap **Customize**, then add the **Reminders** widget below the clock.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var deniedView: some View {
        Text("Reminders access was denied. Go to **Settings → Privacy & Security → Reminders** and enable access for this app.")
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

    private func loadLists() {
        availableLists = eventStore.calendars(for: .reminder)
            .map { (id: $0.calendarIdentifier, title: $0.title) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private func loadSelectedList() {
        let store = SelectedListStore()
        selectedListID = store.selectedListID
        selectedListTitle = store.selectedListTitle

        if selectedListID != nil {
            fetchReminders()
        }
    }

    private func selectList(id: String, title: String) {
        selectedListID = id
        selectedListTitle = title

        var store = SelectedListStore()
        store.selectedListID = id
        store.selectedListTitle = title

        WidgetCenter.shared.reloadAllTimelines()
        fetchReminders()
    }

    @MainActor private func fetchReminders() {
        guard let listID = selectedListID else { return }

        Task {
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
                        externalID: reminder.calendarItemExternalIdentifier
                    )
                }

            reminders = Array(sortReminders(items).prefix(3))
        }
    }
}
