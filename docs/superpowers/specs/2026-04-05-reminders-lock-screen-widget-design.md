# Reminders Lock Screen Widget — Design Spec

## Overview

An iOS app that provides a Lock Screen widget displaying 3 reminders from a user-chosen list. Tapping the widget opens the Reminders app. This replicates the behavior of Apple's original Reminders widget before they changed it to show only 2 reminders with tap-to-complete.

## Platform & Requirements

- **Minimum iOS:** 17.0
- **Frameworks:** SwiftUI, WidgetKit, App Intents, EventKit
- **Widget Family:** `accessoryRectangular` only (Lock Screen)
- **Configuration:** App Intents (`AppIntentConfiguration`)

## Targets

### 1. RemindersWidget (Host App)

Minimal SwiftUI app with a single screen:

- Requests EventKit permission on launch (`EKEventStore.requestFullAccessToReminders()`)
- Displays instructions for adding the widget to the Lock Screen
- No other functionality

### 2. RemindersWidgetExtension (Widget Extension)

Lock Screen widget that displays 3 reminders from a configured list.

**Shared App Group:** Both targets use a shared App Group for any necessary data sharing via `UserDefaults`.

## Widget Configuration

A `SelectListIntent` using App Intents framework:

- User long-presses the widget > Edit Widget to see a list picker
- Picker is populated by querying `EKEventStore` for all available reminder lists
- Selected list identifier is persisted by the intent system
- Unconfigured state shows a "Long press to choose a list" prompt

## Widget Layout

Style: **No title, just reminders with circle indicators** (Option C from brainstorming)

```
 ○ Milk
 ○ Eggs
 ○ Bread
```

- No list title header — maximizes vertical space for 3 reminders
- Open circle indicators on the left (matches Reminders app visual language)
- Reminder text truncates with ellipsis if too long
- Renders in WidgetKit's Lock Screen tinted style

### Edge Cases

- **Fewer than 3 reminders:** Show what's available (1 or 2 items)
- **Empty list:** Show a message like "No reminders"
- **No EventKit access:** Show a prompt to open the app and grant permission
- **No list selected:** Show "Long press to choose a list"

## Data Flow

1. Timeline provider receives the configured list identifier from the App Intent
2. Queries `EKEventStore` for incomplete reminders in that list
3. Sorts reminders: **due date first** (ascending), then **creation date** (ascending) as fallback for reminders without due dates
4. Takes the first 3 reminders
5. Returns a single timeline entry with refresh policy `.after(Date().addingTimeInterval(15 * 60))` (15 minutes)

## Tap Behavior

- Widget uses `.widgetURL()` to set a deep link
- Opens the Reminders app via `x-apple-reminderkit://` URL scheme
- Deep linking to a specific list is not reliably supported by Apple, so the app opens to its default view

## EventKit Permissions

- The host app requests full access to reminders on launch
- The widget extension shares access through the App Group
- `NSRemindersFullAccessUsageDescription` must be set in Info.plist for both targets
