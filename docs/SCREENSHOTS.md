# Screenshot Workflow

Use this when refreshing the screenshots in `docs/`. The full-size screenshots should come from Simulator captures, and the thumbnail files should be generated from those full-size PNGs.

## Screenshot Set

| File | What it shows |
| --- | --- |
| `screenshot-lock-screen-6.5.png` | iPhone Lock Screen with the widget |
| `screenshot-list-view-6.5.png` | iPhone app list view |
| `screenshot-list-selection-6.5.png` | iPhone settings sheet |
| `screenshot-lock-screen-ipad-13.png` | iPad Lock Screen with the widget |
| `screenshot-list-view-ipad-13.png` | iPad app list view |
| `screenshot-list-selection-ipad-13.png` | iPad settings sheet |
| `screenshot-*-thumb.png` | Website thumbnails generated from the iPhone full-size screenshots |

The `6.5` filenames are historical. Keep the filenames stable unless the website code changes too.

## Sample Data

Use habit-style reminders so the streak feature makes sense:

- List: `Daily Routine`
- Reminders:
  - `Take vitamins`
  - `Walk 10 minutes`
  - `Read 10 pages`
- Streak goal: `Complete All`
- Screenshot streak state: `7-day streak`, best `12 days`, with today's reminders still pending

## Setup

Use Xcode's developer directory explicitly if this shell points at Command Line Tools:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodegen generate
```

Use an iPhone Plus/Pro Max simulator for the phone screenshots and an iPad Pro 13-inch simulator for the iPad screenshots. Current good choices are:

- `iPhone 16 Plus`
- `iPad Pro 13-inch (M5)`

Find exact device IDs with:

```bash
xcrun simctl list devices available
```

Set variables for the rest of the commands:

```bash
PHONE="<iPhone simulator UUID>"
IPAD="<iPad simulator UUID>"
APP_ID="com.brianpattison.RemindersWidget"
```

Boot the devices, grant Reminders access, and make the status bars deterministic:

```bash
xcrun simctl boot "$PHONE" || true
xcrun simctl boot "$IPAD" || true
xcrun simctl privacy "$PHONE" grant reminders "$APP_ID"
xcrun simctl privacy "$IPAD" grant reminders "$APP_ID"

xcrun simctl status_bar "$PHONE" override \
  --time 9:41 \
  --batteryState charged --batteryLevel 100 \
  --wifiBars 3 --cellularBars 4

xcrun simctl status_bar "$IPAD" override \
  --time 9:41 \
  --batteryState charged --batteryLevel 100 \
  --wifiBars 3 --cellularBars 4
```

Build and install the app:

```bash
DD=/tmp/RemindersWidgetScreenshotsDD
xcodebuild build -scheme RemindersWidget -destination "id=$PHONE" -derivedDataPath "$DD" -quiet
APP="$DD/Build/Products/Debug-iphonesimulator/RemindersWidget.app"
xcrun simctl install "$PHONE" "$APP"
xcrun simctl install "$IPAD" "$APP"
```

## Seed The Simulator

The simplest reliable path is manual setup in Simulator:

1. Open Reminders in each simulator.
2. Create the `Daily Routine` list.
3. Add the three reminders listed above.
4. Launch `Lock Screen`.
5. In the app settings sheet, choose `Daily Routine`.
6. Set the streak goal to `Complete All`.

After selecting the list, set the streak defaults so the app shows `7-day streak` on launch. `Complete All` still uses the stored raw value `emptyList`. Run this once per device:

```bash
DEVICE="$PHONE" # then repeat with DEVICE="$IPAD"
GROUP=$(xcrun simctl get_app_container "$DEVICE" "$APP_ID" groups | awk '/group.com.brianpattison.RemindersWidget/{print $2}')
PREF="$GROUP/Library/Preferences/group.com.brianpattison.RemindersWidget.plist"
LIST_ID=$(/usr/libexec/PlistBuddy -c "Print :selectedListID" "$PREF")
YESTERDAY=$(date -v-1d -v0H -v0M -v0S +%s)

/usr/libexec/PlistBuddy -c "Set :streakMode emptyList" "$PREF" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :streakMode string emptyList" "$PREF"
/usr/libexec/PlistBuddy -c "Set :streakListID $LIST_ID" "$PREF" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :streakListID string $LIST_ID" "$PREF"
/usr/libexec/PlistBuddy -c "Set :streakCurrentCount 7" "$PREF" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :streakCurrentCount integer 7" "$PREF"
/usr/libexec/PlistBuddy -c "Set :streakBestCount 12" "$PREF" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :streakBestCount integer 12" "$PREF"
/usr/libexec/PlistBuddy -c "Set :streakLastQualifiedDay $YESTERDAY" "$PREF" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :streakLastQualifiedDay real $YESTERDAY" "$PREF"
```

The app should keep the `7-day streak` count and show `Complete all reminders today.` until the sample reminders are completed.

## Capture App Screens

Launch normally for the list view:

```bash
xcrun simctl launch --terminate-running-process "$PHONE" "$APP_ID"
sleep 2
xcrun simctl io "$PHONE" screenshot docs/screenshot-list-view-6.5.png

xcrun simctl launch --terminate-running-process "$IPAD" "$APP_ID"
sleep 2
xcrun simctl io "$IPAD" screenshot docs/screenshot-list-view-ipad-13.png
```

For the settings screenshots, open the app and tap the gear button, then capture:

```bash
xcrun simctl io "$PHONE" screenshot docs/screenshot-list-selection-6.5.png
xcrun simctl io "$IPAD" screenshot docs/screenshot-list-selection-ipad-13.png
```

## Capture Lock Screen Screens

Use the same seeded device and selected list.

1. Lock the simulator from Simulator's toolbar or Device menu.
2. Long-press the Lock Screen.
3. Tap `Customize`, choose the Lock Screen, and add the Reminders widget below the clock.
4. Make sure the widget shows the three `Daily Routine` reminders.
5. Capture:

```bash
xcrun simctl io "$PHONE" screenshot docs/screenshot-lock-screen-6.5.png
xcrun simctl io "$IPAD" screenshot docs/screenshot-lock-screen-ipad-13.png
```

If the widget shows stale data, open the app, reselect the list, wait a few seconds, and return to the Lock Screen.

## Generate Thumbnails

Generate thumbnails only from the iPhone full-size images:

```bash
python3 - <<'PY'
from PIL import Image

pairs = [
    ("docs/screenshot-lock-screen-6.5.png", "docs/screenshot-lock-screen-thumb.png"),
    ("docs/screenshot-list-view-6.5.png", "docs/screenshot-list-view-thumb.png"),
    ("docs/screenshot-list-selection-6.5.png", "docs/screenshot-list-selection-thumb.png"),
]

for src, dst in pairs:
    image = Image.open(src).convert("RGB")
    image = image.resize((360, 779), Image.Resampling.LANCZOS)
    image.save(dst, optimize=True)
PY
```

## Verify

Check dimensions and build before finishing:

```bash
sips -g pixelWidth -g pixelHeight docs/*.png
xcodebuild build -scheme RemindersWidget -destination "id=$PHONE" -quiet
git status --short
```

Expected thumbnail size is `360 x 779`. The iPad screenshots should be `2064 x 2752`. Phone screenshot dimensions may vary by the simulator used; keep them as direct Simulator output and do not stretch them.
