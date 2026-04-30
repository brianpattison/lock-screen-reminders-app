# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

An iOS app that provides a Lock Screen widget for the Reminders app. The widget displays **three** reminders from a user-chosen list (vs Apple's native Lock Screen widget which shows two). Tapping the widget opens the Reminders app to the selected list rather than marking reminders as completed.

## Tech Stack

- **Language:** Swift
- **Frameworks:** SwiftUI, WidgetKit, App Intents, EventKit
- **Platform:** iOS 17+
- **Build System:** Xcode (project generated via XcodeGen from `project.yml`)

## Build Commands

```bash
# Generate Xcode project (required after changing project.yml)
xcodegen generate

# Build the project
xcodebuild build -scheme RemindersWidget -destination 'platform=iOS Simulator,name=iPhone 16' -quiet

# Run tests
xcodebuild test -scheme RemindersWidgetTests -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

## Architecture

Two targets in one Xcode project:

- **RemindersWidget** (host app): Minimal SwiftUI app that requests EventKit permission and shows Lock Screen widget setup instructions. Handles widget tap by redirecting to the Reminders app.
- **RemindersWidgetExtension** (widget extension): `accessoryRectangular` Lock Screen widget using `AppIntentConfiguration`. Users pick a Reminders list via Edit Widget (powered by `SelectListIntent` + `ReminderListEntity`). The `RemindersTimelineProvider` fetches incomplete reminders via EventKit, sorts by due date then creation date, and displays the first 3.
- **Shared/**: `ReminderItem` model and `sortReminders()` function, compiled into both the extension and test targets.

## App Icon

```bash
# Generate the app icon (requires numpy and Pillow)
python3 generate_icon.py AppIcon.png
```
