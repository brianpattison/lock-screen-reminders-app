# App Store Minimum Functionality Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the host app with a list picker and live widget preview, move widget configuration from intent-based to app-driven via App Group, and fix the permission button text.

**Architecture:** The host app becomes the single place to select which Reminders list the widget displays, sharing the reminder row rendering with the widget extension via a shared `ReminderListView`. Data flows through an App Group `UserDefaults` — the app writes the selected list, the widget reads it. The widget switches from `AppIntentConfiguration` to `StaticConfiguration`.

**Tech Stack:** Swift, SwiftUI, WidgetKit, EventKit, XcodeGen

---

### Task 1: Add App Group entitlements and update project.yml

**Files:**
- Create: `RemindersWidget/RemindersWidget.entitlements`
- Create: `RemindersWidgetExtension/RemindersWidgetExtension.entitlements`
- Modify: `project.yml`

- [ ] **Step 1: Create host app entitlements file**

Create `RemindersWidget/RemindersWidget.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.brianpattison.RemindersWidget</string>
    </array>
</dict>
</plist>
```

- [ ] **Step 2: Create widget extension entitlements file**

Create `RemindersWidgetExtension/RemindersWidgetExtension.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.brianpattison.RemindersWidget</string>
    </array>
</dict>
</plist>
```

- [ ] **Step 3: Update project.yml**

Three changes to `project.yml`:

1. Add `CODE_SIGN_ENTITLEMENTS` to the `RemindersWidget` target settings:

```yaml
        CODE_SIGN_ENTITLEMENTS: RemindersWidget/RemindersWidget.entitlements
```

2. Add `Shared` to the `RemindersWidget` target sources:

```yaml
    sources:
      - path: RemindersWidget
      - path: Assets.xcassets
      - path: Shared
```

3. Add `CODE_SIGN_ENTITLEMENTS` to the `RemindersWidgetExtension` target settings:

```yaml
        CODE_SIGN_ENTITLEMENTS: RemindersWidgetExtension/RemindersWidgetExtension.entitlements
```

- [ ] **Step 4: Regenerate and build**

Run:

```bash
xcodegen generate && xcodebuild build -scheme RemindersWidget -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: Build succeeds.

- [ ] **Step 5: Commit**

```bash
git add RemindersWidget/RemindersWidget.entitlements RemindersWidgetExtension/RemindersWidgetExtension.entitlements project.yml
git commit -m "Add App Group entitlements and add Shared sources to host app"
```

---

### Task 2: Create SelectedListStore

**Files:**
- Create: `Shared/SelectedListStore.swift`
- Modify: `Tests/ReminderSortingTests.swift` → rename to `Tests/SharedTests.swift` (or create new test file)

- [ ] **Step 1: Write the failing test**

Create `Tests/SelectedListStoreTests.swift`:

```swift
import XCTest

final class SelectedListStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: SelectedListStore!

    override func setUp() {
        super.setUp()
        suiteName = "test-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        store = SelectedListStore(defaults: defaults)
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testDefaultsToNil() {
        XCTAssertNil(store.selectedListID)
        XCTAssertNil(store.selectedListTitle)
    }

    func testPersistsSelectedList() {
        store.selectedListID = "calendar-123"
        store.selectedListTitle = "Groceries"

        XCTAssertEqual(store.selectedListID, "calendar-123")
        XCTAssertEqual(store.selectedListTitle, "Groceries")
    }

    func testPersistsAcrossInstances() {
        store.selectedListID = "calendar-456"
        store.selectedListTitle = "Work"

        let store2 = SelectedListStore(defaults: defaults)
        XCTAssertEqual(store2.selectedListID, "calendar-456")
        XCTAssertEqual(store2.selectedListTitle, "Work")
    }

    func testTodayID() {
        XCTAssertEqual(SelectedListStore.todayID, "com.brianpattison.RemindersWidget.today")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
xcodegen generate && xcodebuild test -scheme RemindersWidgetTests -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: FAIL — `SelectedListStore` not defined.

- [ ] **Step 3: Write minimal implementation**

Create `Shared/SelectedListStore.swift`:

```swift
import Foundation

struct SelectedListStore {
    static let todayID = "com.brianpattison.RemindersWidget.today"

    private static let suiteName = "group.com.brianpattison.RemindersWidget"
    private static let listIDKey = "selectedListID"
    private static let listTitleKey = "selectedListTitle"

    private let defaults: UserDefaults

    init(defaults: UserDefaults? = nil) {
        self.defaults = defaults ?? UserDefaults(suiteName: Self.suiteName) ?? .standard
    }

    var selectedListID: String? {
        get { defaults.string(forKey: Self.listIDKey) }
        set { defaults.set(newValue, forKey: Self.listIDKey) }
    }

    var selectedListTitle: String? {
        get { defaults.string(forKey: Self.listTitleKey) }
        set { defaults.set(newValue, forKey: Self.listTitleKey) }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:

```bash
xcodebuild test -scheme RemindersWidgetTests -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: All tests PASS (both the new `SelectedListStoreTests` and existing `ReminderSortingTests`).

- [ ] **Step 5: Commit**

```bash
git add Shared/SelectedListStore.swift Tests/SelectedListStoreTests.swift
git commit -m "Add SelectedListStore for App Group UserDefaults"
```

---

### Task 3: Extract ReminderListView into Shared

**Files:**
- Create: `Shared/ReminderListView.swift`
- Modify: `RemindersWidgetExtension/RemindersWidgetView.swift`

- [ ] **Step 1: Create shared ReminderListView**

Create `Shared/ReminderListView.swift`:

```swift
import SwiftUI

struct ReminderListView: View {
    let reminders: [ReminderItem]

    var body: some View {
        let count = reminders.count
        let textFont: Font = count >= 3 ? .caption : .body
        let circleSize: CGFloat = count >= 3 ? 10 : 13
        VStack(alignment: .leading, spacing: count >= 3 ? 2 : 6) {
            ForEach(Array(reminders.enumerated()), id: \.offset) { _, reminder in
                Link(destination: reminder.widgetURL) {
                    HStack(spacing: 5) {
                        Image(systemName: "circle")
                            .font(.system(size: circleSize))
                        Text(reminder.title)
                            .font(textFont)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
```

- [ ] **Step 2: Update RemindersWidgetView to use ReminderListView**

Replace the full contents of `RemindersWidgetExtension/RemindersWidgetView.swift` with:

```swift
import SwiftUI
import WidgetKit

struct RemindersWidgetView: View {
    let entry: ReminderEntry

    var body: some View {
        switch entry.state {
        case .notConfigured:
            Text("Open app to select a list")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .noAccess:
            Text("Open app to grant Reminders access")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .empty:
            Text("No reminders")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .configured:
            ReminderListView(reminders: entry.reminders)
        }
    }
}
```

Note: the `notConfigured` message changes from "Customize Lock Screen to set list" to "Open app to select a list" since configuration now happens in the app.

- [ ] **Step 3: Regenerate and build to verify**

Run:

```bash
xcodegen generate && xcodebuild build -scheme RemindersWidget -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: Build succeeds. (`xcodegen generate` is needed so the new `ReminderListView.swift` is included in the project.)

- [ ] **Step 4: Run tests to verify nothing broke**

Run:

```bash
xcodebuild test -scheme RemindersWidgetTests -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Shared/ReminderListView.swift RemindersWidgetExtension/RemindersWidgetView.swift
git commit -m "Extract ReminderListView into Shared for use by both targets"
```

---

### Task 4: Switch widget to StaticConfiguration

**Files:**
- Modify: `RemindersWidgetExtension/RemindersTimelineProvider.swift`
- Modify: `RemindersWidgetExtension/RemindersLockScreenWidget.swift`
- Delete: `RemindersWidgetExtension/SelectListIntent.swift`
- Delete: `RemindersWidgetExtension/ReminderListEntity.swift`

- [ ] **Step 1: Rewrite RemindersTimelineProvider**

Replace the full contents of `RemindersWidgetExtension/RemindersTimelineProvider.swift` with:

```swift
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
```

- [ ] **Step 2: Update RemindersLockScreenWidget to StaticConfiguration**

Replace the full contents of `RemindersWidgetExtension/RemindersLockScreenWidget.swift` with:

```swift
import SwiftUI
import WidgetKit

struct RemindersLockScreenWidget: Widget {
    let kind = "RemindersLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: RemindersTimelineProvider()
        ) { entry in
            RemindersWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(URL(string: "reminderswidget://open")!)
        }
        .configurationDisplayName("Reminders")
        .description("Display reminders from a chosen list.")
        .supportedFamilies([.accessoryRectangular])
    }
}
```

- [ ] **Step 3: Delete intent files**

```bash
rm RemindersWidgetExtension/SelectListIntent.swift RemindersWidgetExtension/ReminderListEntity.swift
```

- [ ] **Step 4: Regenerate and build**

Run:

```bash
xcodegen generate && xcodebuild build -scheme RemindersWidget -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: Build succeeds.

- [ ] **Step 5: Run tests**

Run:

```bash
xcodebuild test -scheme RemindersWidgetTests -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Switch widget to StaticConfiguration, remove intent-based list selection"
```

---

### Task 5: Redesign ContentView with list picker and widget preview

**Files:**
- Modify: `RemindersWidget/ContentView.swift`

- [ ] **Step 1: Rewrite ContentView**

Replace the full contents of `RemindersWidget/ContentView.swift` with:

```swift
import EventKit
import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var authStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
    @State private var selectedListID: String?
    @State private var selectedListTitle: String?
    @State private var availableLists: [(id: String, title: String)] = []
    @State private var reminders: [ReminderItem] = []
    @Environment(\.openURL) private var openURL

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

    private func fetchReminders() {
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
```

- [ ] **Step 2: Build to verify**

Run:

```bash
xcodebuild build -scheme RemindersWidget -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: Build succeeds.

- [ ] **Step 3: Run all tests**

Run:

```bash
xcodebuild test -scheme RemindersWidgetTests -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: All tests PASS.

- [ ] **Step 4: Commit**

```bash
git add RemindersWidget/ContentView.swift
git commit -m "Redesign host app with list picker and widget preview"
```

---

### Task 6: Final verification

- [ ] **Step 1: Clean build**

Run:

```bash
xcodebuild clean build -scheme RemindersWidget -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: Build succeeds with no warnings related to our changes.

- [ ] **Step 2: Run all tests**

Run:

```bash
xcodebuild test -scheme RemindersWidgetTests -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: All tests PASS.

- [ ] **Step 3: Verify deleted files are gone**

Run:

```bash
ls RemindersWidgetExtension/SelectListIntent.swift RemindersWidgetExtension/ReminderListEntity.swift 2>&1
```

Expected: "No such file or directory" for both files.

- [ ] **Step 4: Review git log**

Run:

```bash
git log --oneline -6
```

Expected: 5 new commits on top of the existing history:
1. Add App Group entitlements and add Shared sources to host app
2. Add SelectedListStore for App Group UserDefaults
3. Extract ReminderListView into Shared for use by both targets
4. Switch widget to StaticConfiguration, remove intent-based list selection
5. Redesign host app with list picker and widget preview
