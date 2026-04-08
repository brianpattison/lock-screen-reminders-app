import EventKit
import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var authStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
    @State private var selectedListID: String?
    @State private var selectedListTitle: String?
    @State private var selectedListColor: Color = .blue
    @State private var availableLists: [(id: String, title: String, color: Color)] = []
    @State private var showSettings = false

    private let eventStore = EKEventStore()

    var body: some View {
        Group {
            if authStatus == .fullAccess, let listID = selectedListID, let listTitle = selectedListTitle {
                ReminderDetailView(
                    listID: listID,
                    listTitle: listTitle,
                    listColor: selectedListColor,
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
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checklist")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Lock Screen Reminders")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Tap the gear icon to open settings and get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Settings Sheet

    private var settingsSheet: some View {
        NavigationStack {
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

            Text("Long press your Lock Screen, tap **Customize**, then add the **Reminders** widget below the clock.")
                .font(.caption)
                .foregroundStyle(.secondary)
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
            } else if let list = availableLists.first(where: { $0.id == listID }) {
                selectedListTitle = list.title
                selectedListColor = list.color
            } else {
                // Stored list no longer exists
                selectedListID = nil
                selectedListTitle = nil
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
    }
}
