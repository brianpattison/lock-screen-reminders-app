# Reminders Lock Screen Widget

The Reminders app for iOS has an official Lock Screen widget by Apple that displays two reminders and allows you to tap on either of them to mark them as completed. The original widget by Apple displayed three reminders, and when you would tap on them it would open the Reminders app to the list you selected to display. I very much preferred this because of the ability to see the extra reminder and also not accidentally mark a reminder as completed by bumping the screen.

This app copies the original Reminders Lock Screen widget idea and displays first three reminders from the list you choose and opens the Reminders app to the chosen list when you tap anywhere on the widget.

## App Icon

Generate the app icon with:

```bash
python3 generate_icon.py AppIcon.png
```

Requires `numpy` and `Pillow` (`pip install numpy Pillow`).

## Development

Format Swift files with Apple's `swift-format`:

```bash
swift-format format --configuration .swift-format --recursive --parallel --in-place RemindersWidget RemindersWidgetExtension Shared Tests
```

Validate formatting with:

```bash
swift-format lint --configuration .swift-format --recursive --parallel --strict RemindersWidget RemindersWidgetExtension Shared Tests
```
