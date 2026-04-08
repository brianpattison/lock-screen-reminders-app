# In-App Reminder List View

## Summary

Replace the current "redirect to Apple Reminders" behavior with an in-app list view that shows all incomplete reminders from the selected list, allows marking them as completed, and triggers widget refresh on completion.

## Changes

### 1. App Navigation (Approach C: List view as root, settings as sheet)

- **Root view**: `ReminderDetailView` showing the selected list's reminders
  - List title at top, colored with `EKCalendar.cgColor` (system blue for "Today")
  - Gear icon (SF Symbol `gearshape`) top-right, presents settings sheet
  - Scrollable list of ALL incomplete reminders (no 3-item limit)
  - Each row: circle checkbox + title. Tap checkbox to complete.
- **Settings sheet** (auto-presented when no list selected or not authorized):
  - Permission request (if needed)
  - List picker (Today + all reminder calendars)
  - Widget setup instructions
- **No list selected**: Root view empty, sheet auto-presents
- **First launch**: Sheet auto-presents for permission + list selection

### 2. Completing Reminders

- Tap checkbox -> `eventStore.save(reminder, commit: true)` with `isCompleted = true`
- Brief animation: filled checkbox + strikethrough (~0.5-1s)
- Row animates out of list
- `WidgetCenter.shared.reloadAllTimelines()` called after completion

### 3. Widget Refresh Strategy

- Keep 15-minute background timeline refresh (current behavior)
- Add: reload all timelines when app comes to foreground (`scenePhase == .active`)
- Add: reload after marking a reminder as completed in-app

### 4. Widget Tap Behavior

- Entire widget is one tap area (remove individual `Link` per reminder)
- Tap opens the app to the list view (no redirect to Apple Reminders)
- `widgetURL` stays as `reminderswidget://open`

### 5. Model Changes

- `ReminderItem`: Remove `externalID` and `widgetURL`. Add `calendarItemIdentifier: String?` for completing reminders via EventKit.
- `ReminderListView` (widget): Remove `Link` wrapper, display rows directly.

### 6. Files Changed

| File | Change |
|------|--------|
| `Shared/ReminderItem.swift` | Remove `externalID`/`widgetURL`, add `calendarItemIdentifier` |
| `Shared/ReminderListView.swift` | Remove `Link` wrapper from rows |
| `RemindersWidget/ContentView.swift` | Refactor: root shows detail view, sheet for settings |
| `RemindersWidget/ReminderDetailView.swift` | **New**: full reminder list with completion |
| `RemindersWidget/RemindersWidgetApp.swift` | Remove `onOpenURL` redirect to Apple Reminders |
| `RemindersWidgetExtension/RemindersTimelineProvider.swift` | Update `ReminderItem` construction |
| `Tests/ReminderSortingTests.swift` | Update `ReminderItem` constructors |
