# App Store Minimum Functionality — Design Spec

**Date:** 2026-04-08
**Context:** Apple rejected v1.0 for Guideline 4.2 (Minimum Functionality). The host app only requested permission and showed static widget setup instructions. This redesign adds a list picker and live widget preview to the host app, while also addressing Guideline 5.1.1(iv) (button text) and switching widget configuration from intent-based to app-driven.

## Goals

- Pass Apple's Guideline 4.2 by making the host app useful on its own
- Move widget list selection into the host app (remove finicky widget edit flow)
- Share widget rendering code between the app and extension
- Fix "Grant Reminders Access" button text (Guideline 5.1.1(iv))

## Architecture Changes

### Data Sharing via App Group

- Add App Group entitlement (`group.com.brianpattison.RemindersWidget`) to both the host app and widget extension targets in `project.yml`
- Create a shared helper in `Shared/` that reads/writes the selected list ID and title to `UserDefaults(suiteName: "group.com.brianpattison.RemindersWidget")`
- When the app changes the selected list, write to shared defaults and call `WidgetCenter.shared.reloadAllTimelines()` to refresh the widget

### Widget Configuration Change

- Switch `RemindersLockScreenWidget` from `AppIntentConfiguration` to `StaticConfiguration`
- Change `RemindersTimelineProvider` from `AppIntentTimelineProvider` to `TimelineProvider` — read selected list ID from shared `UserDefaults` instead of from the intent
- Remove `SelectListIntent` and `ReminderListEntity` — list selection is now handled entirely by the host app
- The `notConfigured` widget state means "user hasn't picked a list in the app yet"

### Shared View Code

- **New `ReminderListView` in `Shared/`** — takes `[ReminderItem]` and renders circle + title rows with `Link(destination:)` for tap handling. This is the core rendering shared by both targets.
- **`RemindersWidgetView` stays in the extension** — handles widget-specific state cases (`notConfigured`, `noAccess`, `empty`) and delegates to `ReminderListView` for the `configured` case.
- **Host app** wraps `ReminderListView` in a styled container that mimics Lock Screen widget appearance. The app handles its own states (no permission, no list selected) separately in `ContentView`.
- WidgetKit stays out of `Shared/` — only SwiftUI and Foundation are needed.

### Host App Redesign (`ContentView`)

Single-screen app with two modes based on permission state:

**Before permission granted:**
- App icon + title
- Explanation text
- "Continue" button that triggers the EventKit permission prompt (fixes Guideline 5.1.1(iv))
- If denied: message directing user to Settings

**After permission granted (main screen):**
- App icon + title at top
- **Dropdown list picker** — `Menu` showing all reminder lists + "Today". No default selection; widget shows "not configured" until the user picks a list. Selection persists to App Group UserDefaults and triggers widget timeline reload.
- **"Widget Preview" label + `ReminderListView`** in a styled container — live data from EventKit, same tap behavior (opens Reminders app via URL scheme)
- **Setup hint** at bottom — compact Lock Screen customization instructions

**Data refresh:** Fetch reminders on appear and when selected list changes. Reminder-fetching logic is implemented directly in the host app using EventKit (does not reuse the timeline provider machinery).

**Deep linking:** Existing `reminderswidget://open` URL handling stays the same.

## Files Changed

| File | Change |
|------|--------|
| `project.yml` | Add App Group entitlement to both targets; add `Shared/` to host app sources |
| `Shared/ReminderListView.swift` | New — shared reminder row rendering view |
| `Shared/SelectedListStore.swift` | New — App Group UserDefaults helper for selected list |
| `RemindersWidget/ContentView.swift` | Redesign — list picker, widget preview, "Continue" button |
| `RemindersWidgetExtension/RemindersLockScreenWidget.swift` | Switch to `StaticConfiguration` |
| `RemindersWidgetExtension/RemindersTimelineProvider.swift` | Switch to `TimelineProvider`, read list from UserDefaults |
| `RemindersWidgetExtension/RemindersWidgetView.swift` | Delegate to shared `ReminderListView` for configured state |
| `RemindersWidgetExtension/SelectListIntent.swift` | Remove |
| `RemindersWidgetExtension/ReminderListEntity.swift` | Remove |

## Out of Scope

- Reminder creation, editing, or completion in the host app
- Multiple widget instances with different lists
- Home Screen widget families
- Support URL fix (Guideline 1.5) — metadata-only change in App Store Connect
