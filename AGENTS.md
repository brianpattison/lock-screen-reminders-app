# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, Codex, etc.) working in this repository.

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

# Lint Swift formatting (matches GitHub Actions)
swift-format lint --configuration .swift-format --recursive --parallel --strict RemindersWidget RemindersWidgetExtension Shared Tests

# Run tests
xcodebuild test -scheme RemindersWidgetTests -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

After making code changes, do not present the work as completed until the same checks used by the GitHub Actions workflow pass locally: the `swift-format lint` command above and the `xcodebuild test` command for `RemindersWidgetTests`. Check `.github/workflows/ci.yml` before running them to make sure the local commands still match CI. If `iPhone 16` is not installed locally, use another available iOS simulator destination.

## Architecture

Two targets in one Xcode project:

- **RemindersWidget** (host app): Minimal SwiftUI app that requests EventKit permission and shows Lock Screen widget setup instructions. Handles widget tap by redirecting to the Reminders app.
- **RemindersWidgetExtension** (widget extension): `accessoryRectangular` Lock Screen widget using `StaticConfiguration`. The selected Reminders list is chosen in the host app's settings sheet and shared with the extension through the App Group store (`SelectedListStore`). The `RemindersTimelineProvider` reads the stored list ID, fetches incomplete reminders via EventKit, sorts by due date then creation date, and displays the first 3.
- **Shared/**: `ReminderItem` model and `sortReminders()` function, compiled into both the extension and test targets.

## App Icon

```bash
# Generate the app icon (requires numpy and Pillow)
python3 generate_icon.py AppIcon.png
```

## Docs Screenshots

When updating `docs/screenshot-*.png`, follow the detailed workflow in `docs/SCREENSHOTS.md`. It documents the sample Reminders data, Simulator setup, capture filenames, dimension checks, and thumbnail generation command.
