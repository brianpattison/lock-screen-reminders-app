# Reminders Lock Screen Widget Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an iOS Lock Screen widget that displays 3 reminders from a user-chosen list and opens the Reminders app on tap.

**Architecture:** Minimal host app (permission request + instructions) with a WidgetKit extension using `AppIntentConfiguration` for list selection. EventKit reads reminders; the widget renders them in `accessoryRectangular` format. Tapping the widget opens the host app, which immediately redirects to the Reminders app.

**Tech Stack:** Swift, SwiftUI, WidgetKit, App Intents, EventKit, XcodeGen

---

## File Structure

```
project.yml                                  # XcodeGen project specification
RemindersWidget/
  RemindersWidgetApp.swift                   # @main host app entry point
  ContentView.swift                          # Instructions screen + EventKit permission
Assets.xcassets/
  Contents.json                              # Asset catalog root
  AppIcon.appiconset/
    Contents.json                            # App icon placeholder
RemindersWidgetExtension/
  RemindersWidgetBundle.swift                # @main widget bundle entry point
  RemindersLockScreenWidget.swift            # Widget definition
  RemindersTimelineProvider.swift            # AppIntentTimelineProvider
  RemindersWidgetView.swift                  # Widget SwiftUI view
  ReminderEntry.swift                        # TimelineEntry model
  ReminderListEntity.swift                   # AppEntity for reminder lists
  SelectListIntent.swift                     # WidgetConfigurationIntent
Shared/
  ReminderItem.swift                         # Reminder data model + sort logic
Tests/
  ReminderSortingTests.swift                 # Unit tests for sort logic
```

---

### Task 1: Create project scaffolding

**Files:**
- Create: `project.yml`
- Create: `Assets.xcassets/Contents.json`
- Create: `Assets.xcassets/AppIcon.appiconset/Contents.json`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p RemindersWidget RemindersWidgetExtension Shared Tests Assets.xcassets/AppIcon.appiconset
```

- [ ] **Step 2: Create project.yml**

```yaml
name: RemindersWidget
options:
  bundleIdPrefix: com.brianpattison
  deploymentTarget:
    iOS: "17.0"
  generateEmptyDirectories: true
targets:
  RemindersWidget:
    type: application
    platform: iOS
    sources:
      - path: RemindersWidget
      - path: Assets.xcassets
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.brianpattison.RemindersWidget
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
        INFOPLIST_KEY_CFBundleDisplayName: Reminders Widget
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
    info:
      properties:
        UILaunchScreen: {}
        NSRemindersFullAccessUsageDescription: "This app needs access to your reminders to display them in the Lock Screen widget."
    dependencies:
      - target: RemindersWidgetExtension
  RemindersWidgetExtension:
    type: app-extension
    platform: iOS
    sources:
      - path: RemindersWidgetExtension
      - path: Shared
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.brianpattison.RemindersWidget.WidgetExtension
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
        INFOPLIST_KEY_CFBundleDisplayName: Reminders Widget
    info:
      properties:
        NSExtension:
          NSExtensionPointIdentifier: com.apple.widgetkit-extension
        NSRemindersFullAccessUsageDescription: "This widget needs access to your reminders to display them on your Lock Screen."
  RemindersWidgetTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: Tests
      - path: Shared
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.brianpattison.RemindersWidget.Tests
    info:
      properties: {}
    dependencies:
      - target: RemindersWidget
```

- [ ] **Step 3: Create asset catalog files**

`Assets.xcassets/Contents.json`:
```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

`Assets.xcassets/AppIcon.appiconset/Contents.json`:
```json
{
  "images" : [
    {
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add project.yml Assets.xcassets
git commit -m "feat: add XcodeGen project configuration and asset catalog"
```

---

### Task 2: Create ReminderItem model and sorting logic

**Files:**
- Create: `Shared/ReminderItem.swift`

- [ ] **Step 1: Write ReminderItem struct and sortReminders function**

```swift
import Foundation

struct ReminderItem {
    let title: String
    let dueDate: Date?
    let creationDate: Date?
}

func sortReminders(_ reminders: [ReminderItem]) -> [ReminderItem] {
    reminders.sorted { r1, r2 in
        switch (r1.dueDate, r2.dueDate) {
        case let (d1?, d2?):
            return d1 < d2
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            let c1 = r1.creationDate ?? .distantPast
            let c2 = r2.creationDate ?? .distantPast
            return c1 < c2
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Shared/ReminderItem.swift
git commit -m "feat: add ReminderItem model and sort logic"
```

---

### Task 3: Write and run sorting tests

**Files:**
- Create: `Tests/ReminderSortingTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
import XCTest

final class ReminderSortingTests: XCTestCase {

    func testSortsByDueDateAscending() {
        let now = Date()
        let reminders = [
            ReminderItem(title: "Later", dueDate: now.addingTimeInterval(200), creationDate: now),
            ReminderItem(title: "Soon", dueDate: now.addingTimeInterval(100), creationDate: now),
            ReminderItem(title: "Earliest", dueDate: now.addingTimeInterval(50), creationDate: now),
        ]

        let sorted = sortReminders(reminders)

        XCTAssertEqual(sorted.map(\.title), ["Earliest", "Soon", "Later"])
    }

    func testDueDateItemsBeforeNoDueDateItems() {
        let now = Date()
        let reminders = [
            ReminderItem(title: "No Due", dueDate: nil, creationDate: now),
            ReminderItem(title: "Has Due", dueDate: now.addingTimeInterval(100), creationDate: now),
        ]

        let sorted = sortReminders(reminders)

        XCTAssertEqual(sorted.map(\.title), ["Has Due", "No Due"])
    }

    func testNoDueDateFallsBackToCreationDateAscending() {
        let now = Date()
        let reminders = [
            ReminderItem(title: "Newer", dueDate: nil, creationDate: now.addingTimeInterval(200)),
            ReminderItem(title: "Older", dueDate: nil, creationDate: now.addingTimeInterval(100)),
            ReminderItem(title: "Oldest", dueDate: nil, creationDate: now),
        ]

        let sorted = sortReminders(reminders)

        XCTAssertEqual(sorted.map(\.title), ["Oldest", "Older", "Newer"])
    }

    func testNilCreationDateTreatedAsDistantPast() {
        let now = Date()
        let reminders = [
            ReminderItem(title: "Has Creation", dueDate: nil, creationDate: now),
            ReminderItem(title: "No Creation", dueDate: nil, creationDate: nil),
        ]

        let sorted = sortReminders(reminders)

        XCTAssertEqual(sorted.map(\.title), ["No Creation", "Has Creation"])
    }

    func testMixedDueDateAndNoDueDate() {
        let now = Date()
        let reminders = [
            ReminderItem(title: "No Due Old", dueDate: nil, creationDate: now),
            ReminderItem(title: "Due Later", dueDate: now.addingTimeInterval(200), creationDate: now),
            ReminderItem(title: "No Due New", dueDate: nil, creationDate: now.addingTimeInterval(100)),
            ReminderItem(title: "Due Soon", dueDate: now.addingTimeInterval(100), creationDate: now),
        ]

        let sorted = sortReminders(reminders)

        XCTAssertEqual(sorted.map(\.title), ["Due Soon", "Due Later", "No Due Old", "No Due New"])
    }

    func testEmptyArrayReturnsEmpty() {
        let sorted = sortReminders([])
        XCTAssertTrue(sorted.isEmpty)
    }
}
```

- [ ] **Step 2: Generate project and run tests to verify they pass**

```bash
brew install xcodegen 2>/dev/null; xcodegen generate
xcodebuild test -scheme RemindersWidgetTests -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: All 6 tests pass. (Tests compile because `Shared/` is included in the test target sources.)

- [ ] **Step 3: Commit**

```bash
git add Tests/ReminderSortingTests.swift
git commit -m "test: add unit tests for reminder sorting logic"
```

---

### Task 4: Create ReminderListEntity and SelectListIntent

**Files:**
- Create: `RemindersWidgetExtension/ReminderListEntity.swift`
- Create: `RemindersWidgetExtension/SelectListIntent.swift`

- [ ] **Step 1: Write ReminderListEntity**

```swift
import AppIntents
import EventKit

struct ReminderListEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Reminder List"
    static var defaultQuery = ReminderListQuery()

    var id: String
    var title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct ReminderListQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ReminderListEntity] {
        let store = EKEventStore()
        return store.calendars(for: .reminder)
            .filter { identifiers.contains($0.calendarIdentifier) }
            .map { ReminderListEntity(id: $0.calendarIdentifier, title: $0.title) }
    }

    func suggestedEntities() async throws -> [ReminderListEntity] {
        let store = EKEventStore()
        return store.calendars(for: .reminder)
            .map { ReminderListEntity(id: $0.calendarIdentifier, title: $0.title) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
}
```

- [ ] **Step 2: Write SelectListIntent**

```swift
import AppIntents
import WidgetKit

struct SelectListIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Reminders List"
    static var description = IntentDescription("Choose which reminders list to display on the Lock Screen.")

    @Parameter(title: "List")
    var reminderList: ReminderListEntity?
}
```

- [ ] **Step 3: Commit**

```bash
git add RemindersWidgetExtension/ReminderListEntity.swift RemindersWidgetExtension/SelectListIntent.swift
git commit -m "feat: add App Intent entity and widget configuration intent"
```

---

### Task 5: Create ReminderEntry model

**Files:**
- Create: `RemindersWidgetExtension/ReminderEntry.swift`

- [ ] **Step 1: Write ReminderEntry**

```swift
import WidgetKit

struct ReminderEntry: TimelineEntry {
    let date: Date
    let reminders: [ReminderItem]
    let state: WidgetState

    enum WidgetState {
        case configured
        case notConfigured
        case noAccess
        case empty
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add RemindersWidgetExtension/ReminderEntry.swift
git commit -m "feat: add ReminderEntry timeline entry model"
```

---

### Task 6: Create timeline provider

**Files:**
- Create: `RemindersWidgetExtension/RemindersTimelineProvider.swift`

- [ ] **Step 1: Write RemindersTimelineProvider**

```swift
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

        let calendars = store.calendars(for: .reminder)
        guard let calendar = calendars.first(where: { $0.calendarIdentifier == listEntity.id }) else {
            return ReminderEntry(date: Date(), reminders: [], state: .notConfigured)
        }

        let predicate = store.predicateForReminders(in: [calendar])
        let ekReminders = await withCheckedContinuation { (continuation: CheckedContinuation<[EKReminder], Never>) in
            _ = store.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
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
```

- [ ] **Step 2: Commit**

```bash
git add RemindersWidgetExtension/RemindersTimelineProvider.swift
git commit -m "feat: add timeline provider with EventKit fetch and sort"
```

---

### Task 7: Create widget view

**Files:**
- Create: `RemindersWidgetExtension/RemindersWidgetView.swift`

- [ ] **Step 1: Write RemindersWidgetView**

```swift
import SwiftUI
import WidgetKit

struct RemindersWidgetView: View {
    let entry: ReminderEntry

    var body: some View {
        switch entry.state {
        case .notConfigured:
            Text("Long press to choose a list")
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
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(entry.reminders.enumerated()), id: \.offset) { _, reminder in
                    HStack(spacing: 4) {
                        Image(systemName: "circle")
                            .font(.system(size: 10))
                        Text(reminder.title)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add RemindersWidgetExtension/RemindersWidgetView.swift
git commit -m "feat: add widget view with all display states"
```

---

### Task 8: Create widget definition and bundle

**Files:**
- Create: `RemindersWidgetExtension/RemindersLockScreenWidget.swift`
- Create: `RemindersWidgetExtension/RemindersWidgetBundle.swift`

- [ ] **Step 1: Write RemindersLockScreenWidget**

```swift
import SwiftUI
import WidgetKit

struct RemindersLockScreenWidget: Widget {
    let kind = "RemindersLockScreenWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectListIntent.self,
            provider: RemindersTimelineProvider()
        ) { entry in
            RemindersWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Reminders")
        .description("Display reminders from a chosen list.")
        .supportedFamilies([.accessoryRectangular])
    }
}
```

- [ ] **Step 2: Write RemindersWidgetBundle**

```swift
import SwiftUI
import WidgetKit

@main
struct RemindersWidgetBundle: WidgetBundle {
    var body: some Widget {
        RemindersLockScreenWidget()
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add RemindersWidgetExtension/RemindersLockScreenWidget.swift RemindersWidgetExtension/RemindersWidgetBundle.swift
git commit -m "feat: add widget definition and bundle entry point"
```

---

### Task 9: Create host app

**Files:**
- Create: `RemindersWidget/RemindersWidgetApp.swift`
- Create: `RemindersWidget/ContentView.swift`

- [ ] **Step 1: Write RemindersWidgetApp**

The host app handles the widget tap URL and redirects to the Reminders app. Widgets always open their containing app on tap, so we immediately redirect.

```swift
import SwiftUI

@main
struct RemindersWidgetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { _ in
                    if let url = URL(string: "x-apple-reminderkit://") {
                        UIApplication.shared.open(url)
                    }
                }
        }
    }
}
```

- [ ] **Step 2: Write ContentView**

```swift
import EventKit
import SwiftUI

struct ContentView: View {
    @State private var authStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .reminder)

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checklist")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("Reminders Widget")
                .font(.largeTitle)
                .fontWeight(.bold)

            Group {
                switch authStatus {
                case .fullAccess:
                    instructionsView
                case .denied, .restricted:
                    deniedView
                default:
                    requestAccessView
                }
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }

    private var instructionsView: some View {
        VStack(spacing: 12) {
            Text("To add the widget:")
                .font(.headline)
                .foregroundStyle(.primary)
            Text("Long press your Lock Screen, tap **Customize**, select the Lock Screen, then tap the widget area below the clock to add the **Reminders** widget.")
                .font(.subheadline)
        }
    }

    private var deniedView: some View {
        Text("Reminders access was denied. Go to **Settings → Privacy & Security → Reminders** and enable access for this app.")
            .font(.subheadline)
    }

    private var requestAccessView: some View {
        Button("Grant Reminders Access") {
            Task {
                let store = EKEventStore()
                _ = try? await store.requestFullAccessToReminders()
                authStatus = EKEventStore.authorizationStatus(for: .reminder)
            }
        }
        .buttonStyle(.borderedProminent)
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add RemindersWidget/RemindersWidgetApp.swift RemindersWidget/ContentView.swift
git commit -m "feat: add host app with permission request and instructions"
```

---

### Task 10: Generate Xcode project and verify build

- [ ] **Step 1: Install XcodeGen if needed**

```bash
which xcodegen || brew install xcodegen
```

- [ ] **Step 2: Generate Xcode project**

```bash
xcodegen generate
```

Expected: `Generated RemindersWidget.xcodeproj` and `Wrote RemindersWidget.xcodeproj`

- [ ] **Step 3: Add generated project and gitignore**

Add to `.gitignore`:

```
# Xcode
*.xcodeproj/xcuserdata/
*.xcworkspace/xcuserdata/
DerivedData/
build/

# XcodeGen
*.xcodeproj

# Superpowers
.superpowers/
```

Note: We gitignore the `.xcodeproj` because XcodeGen regenerates it from `project.yml`. The source of truth is `project.yml`.

```bash
git add .gitignore
git commit -m "chore: add gitignore"
```

- [ ] **Step 4: Build the project**

```bash
xcodebuild build -scheme RemindersWidget -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Run tests**

```bash
xcodebuild test -scheme RemindersWidgetTests -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: All 6 tests pass.

- [ ] **Step 6: Final commit**

```bash
git add -A
git commit -m "feat: complete Reminders Lock Screen Widget implementation"
```
