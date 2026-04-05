# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

An iOS app that provides a Home Screen widget for the Reminders app. The widget displays **three** reminders from a user-chosen list (vs Apple's native widget which shows two). Tapping the widget opens the Reminders app to the selected list rather than marking reminders as completed.

## Tech Stack

- **Language:** Swift
- **Frameworks:** SwiftUI, WidgetKit
- **Platform:** iOS
- **Build System:** Xcode

## Build Commands

```bash
# Build the project
xcodebuild -scheme RemindersWidget -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild -scheme RemindersWidget -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Architecture

This is an iOS app with a widget extension:

- **Main App Target:** Configuration UI for selecting which Reminders list to display
- **Widget Extension:** WidgetKit-based home screen widget that reads reminders via EventKit and displays three items from the chosen list
- Uses `EventKit` / `EKReminder` for accessing the user's reminders
- Widget tap uses deep linking to open the Reminders app to the relevant list
