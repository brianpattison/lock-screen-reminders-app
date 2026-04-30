# App Store Submission Guide -- Reminders Widget

Everything you need to submit Reminders Widget to the App Store: metadata, privacy details, screenshot guidance, and a step-by-step submission walkthrough.

---

## 1. App Store Metadata

### App Name
```
Reminders Widget
```
(18 characters -- within the 30-character limit)

### Subtitle
```
3 Reminders on Lock Screen
```
(27 characters -- within the 30-character limit)

### Promotional Text
```
See 3 reminders on your Lock Screen, manage the matching list in the app, and keep a simple task streak. No ads, no tracking, no account required.
```
(146 characters -- within the 170-character limit. This field can be updated at any time without going through App Review.)

### Description
```
Your Lock Screen should show you what matters. Apple's built-in Reminders widget used to display 3 items -- then they changed it to show only 2, and tapping now marks a reminder as complete instead of opening the app. If you've been frustrated by that change, this app fixes it.

Reminders Widget gives you a clean Lock Screen widget that shows 3 reminders from a list you choose in the app. The app also lets you view that same list, complete reminders, open Reminders when you need the full app, and track a simple streak for staying on top of the selected list.

HOW IT WORKS

1. Install the app and grant access to your reminders.
2. Choose the Reminders list the widget should display.
3. Add the widget to your Lock Screen (long-press your Lock Screen, tap Customize, choose Lock Screen, tap Add Widgets, and select Reminders Widget).
4. View and complete reminders in the app, and keep your streak going with the goal you choose.

WHAT YOU GET

- A Lock Screen widget that displays 3 reminders instead of 2.
- Choose which Reminders list to show from inside the app.
- View and complete reminders from the selected list in a focused native app.
- Track a configurable streak: No Overdue, Daily Progress, or Complete All.
- Tap the widget to open the Reminders app -- no accidental completions.
- Clean design that matches the native iOS look.
- Reminders are sorted by due date, then by creation date, so the most urgent items show first.

PRIVACY FIRST

This app accesses your reminders only to display them in the widget and selected-list view, complete reminders you tap in the app, and calculate your local streak. Nothing leaves your device. There are no analytics, no ads, no accounts, no servers. Your data stays on your phone.

Reminders Widget is a small, focused utility for seeing the right reminders at a glance and keeping one important list under control.
```
(1,425 characters -- well within the 4,000-character limit)

### Keywords
```
reminders,widget,lock screen,to do,tasks,checklist,reminder list,productivity,lockscreen,todo
```
(93 characters -- within the 100-character limit)

**Keyword rationale:**
- "reminders" and "widget" are the two highest-intent terms
- "lock screen" / "lockscreen" covers both search patterns
- "to do" / "todo" / "tasks" / "checklist" capture users searching for task-management widgets
- "reminder list" targets users looking specifically for list-based widgets
- "productivity" is a broad fallback category term

### Category
- **Primary Category:** Productivity
- **Secondary Category:** Utilities

### Age Rating
- **Rating:** 4+ (no age restriction)
- **Reasoning:** The app contains no objectionable content, no web access, no user-generated content, no social features, no purchases, and no third-party ads. Select "None" for every content description during the age rating questionnaire.

### Copyright
```
2026 Brian Pattison
```
(Do not include the copyright symbol -- App Store Connect adds it automatically.)

---

## 2. Privacy Information

### App Privacy on App Store Connect

When you reach the "App Privacy" section in App Store Connect, you will answer a series of questions about data collection. Here is exactly what to select:

**"Does this app collect any data?"** -- Select **No**.

That is the only question you need to answer. Since the app:
- Does not transmit any data off the device
- Does not use analytics or crash reporting SDKs
- Does not serve ads
- Does not have accounts or authentication
- Does not use any third-party frameworks that collect data
- Only reads reminders locally via EventKit to display them in the widget

...the correct answer is "No." The reminders data is read on-device and never collected, stored remotely, or shared with anyone.

Your App Privacy label will show: **No Data Collected**.

### Privacy Policy URL

**A privacy policy URL is required** for all new apps submitted to the App Store, regardless of whether you collect data.

You have a few options:
1. Host a simple privacy policy page on a personal website or GitHub Pages.
2. Use a free privacy policy generator and host the result.

The privacy policy should state, at minimum:

- The app does not collect, store, or transmit any personal data.
- The app accesses reminders on-device solely to display them in the widget.
- No data is shared with third parties.
- No analytics, advertising, or tracking tools are used.
- Contact information (an email address is sufficient).

You will enter this URL in App Store Connect under **App Information > Privacy Policy URL**.

---

## 3. Screenshots Guide

### Required Device Sizes

App Store Connect requires screenshots for at least these display sizes:

| Display Size | Device Examples | Screenshot Dimensions (portrait) |
|---|---|---|
| **6.7-inch** | iPhone 16 Pro Max, iPhone 15 Pro Max, iPhone 16 Plus, iPhone 15 Plus | 1290 x 2796 px |
| **6.1-inch** | iPhone 16 Pro, iPhone 15 Pro, iPhone 14 Pro | 1179 x 2556 px |

You may also want to provide:
| Display Size | Device Examples | Screenshot Dimensions (portrait) |
|---|---|---|
| 6.5-inch | iPhone 14 Plus, iPhone 13 Pro Max, iPhone 12 Pro Max, iPhone 11 Pro Max | 1242 x 2688 px |
| 5.5-inch | iPhone 8 Plus, iPhone 7 Plus (if supporting older devices) | 1242 x 2208 px |

**Tip:** If you provide only the 6.7-inch screenshots, App Store Connect can auto-scale for smaller sizes. But providing device-specific screenshots looks more professional.

### What to Show -- 4 Recommended Screenshots

Since this is a Lock Screen widget app with a useful host app, screenshots should show both the widget and the native selected-list workflow.

**Screenshot 1 -- The Widget in Action**
- Show an iPhone Lock Screen with the Reminders Widget visible in the widget area below the clock.
- The widget should display 3 reminders from a realistic-looking habit list (e.g., "Daily Routine" with items like "Take vitamins," "Walk 10 minutes," and "Read 10 pages").
- This is your hero screenshot. It should immediately communicate what the app does.
- Consider adding a brief overlay caption: "See 3 reminders on your Lock Screen"

**Screenshot 2 -- Native List View**
- Show the app displaying the selected reminder list with the streak summary at the top.
- Include a few realistic reminders and the "Open Reminders" action.
- Overlay caption: "View and complete the selected list"

**Screenshot 3 -- List Selection and Streak Goal**
- Show the settings sheet with the widget list picker, streak goal picker, and widget preview.
- Overlay caption: "Choose a list and streak goal"

**Screenshot 4 -- Comparison with Apple's Widget**
- Side-by-side or before/after showing Apple's native widget (2 reminders) vs. Reminders Widget (3 reminders).
- Overlay caption: "3 reminders instead of 2"

### Capturing Screenshots

- Use the iOS Simulator in Xcode or a physical device.
- In Simulator: select the matching device, then use **File > Screenshot** (or Cmd+S) to save.
- On a physical device: press the Side Button + Volume Up simultaneously.
- Screenshots must be PNG or JPEG format.
- Do not include the device bezel in screenshots -- App Store Connect accepts flat screenshots and can add device frames.

### Important Notes

- Populate the Reminders app in Simulator with sample data before capturing screenshots. You can do this by opening the Reminders app in Simulator and adding items manually, or by using EventKit in a test to create sample reminders.
- Make sure the Lock Screen looks clean: use a simple wallpaper, set an appropriate time (like 9:41 AM, which Apple uses in marketing), and remove distracting notifications.

---

## 4. Complete App Store Submission Steps

This walkthrough assumes you have a paid Apple Developer Program membership ($99/year) and have Xcode installed.

### Step 1: Verify Your Apple Developer Account

1. Open a browser and go to **https://developer.apple.com**.
2. Sign in with your Apple ID.
3. Confirm your membership is active under **Account > Membership**.

### Step 2: Register an App ID

The bundle ID `com.brianpattison.RemindersWidget` needs to be registered.

1. Go to **https://developer.apple.com/account/resources/identifiers/list**.
2. Click the **+** (plus) button to register a new identifier.
3. Select **App IDs**, then click **Continue**.
4. Select **App** as the type, then click **Continue**.
5. Fill in:
   - **Description:** Reminders Widget
   - **Bundle ID:** Select "Explicit" and enter `com.brianpattison.RemindersWidget`
6. Under **Capabilities**, scroll down and enable **App Groups** if not already enabled (you may need this if the widget and app share data -- but for EventKit access, it is not strictly required).
7. Click **Continue**, then **Register**.

Now register the widget extension's App ID:

1. Click **+** again.
2. Select **App IDs** > **Continue** > **App** > **Continue**.
3. Fill in:
   - **Description:** Reminders Widget Extension
   - **Bundle ID:** Select "Explicit" and enter `com.brianpattison.RemindersWidget.WidgetExtension`
4. Click **Continue**, then **Register**.

### Step 3: Set Up Signing (Automatic Signing -- Recommended)

Xcode can handle certificates and provisioning profiles automatically.

1. Open the project in Xcode (run `xcodegen generate` first if you have not already).
2. In the project navigator, click on the **RemindersWidget** project (the blue icon at the top).
3. Select the **RemindersWidget** target.
4. Go to the **Signing & Capabilities** tab.
5. Check **Automatically manage signing**.
6. For **Team**, select your Apple Developer team from the dropdown.
7. Xcode should show a green checkmark and your provisioning profile. If it shows an error, ensure the bundle ID matches what you registered.
8. Repeat for the **RemindersWidgetExtension** target:
   - Select the **RemindersWidgetExtension** target.
   - Check **Automatically manage signing**.
   - Select the same Team.
   - Verify the bundle ID is `com.brianpattison.RemindersWidget.WidgetExtension`.

### Step 4: Create the App in App Store Connect

1. Go to **https://appstoreconnect.apple.com**.
2. Click **Apps** (or **My Apps**).
3. Click the **+** button in the top-left corner, then select **New App**.
4. Fill in the form:
   - **Platforms:** iOS
   - **Name:** Reminders Widget
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** Select `com.brianpattison.RemindersWidget` from the dropdown. (If it does not appear, wait a few minutes after registering the App ID, or click the refresh icon.)
   - **SKU:** Enter a unique identifier, e.g., `reminders-widget-001`
   - **User Access:** Full Access (unless you have a team and want to restrict)
5. Click **Create**.

### Step 5: Configure App Information

You are now on the app's page in App Store Connect. Fill in the following sections:

#### App Information (left sidebar)
1. Click **App Information** in the left sidebar.
2. **Name:** Reminders Widget (already filled in).
3. **Subtitle:** `3 Reminders on Lock Screen`
4. **Category:** Primary = Productivity, Secondary = Utilities.
5. **Content Rights:** Select "This app does not contain, show, or access third-party content."
6. **Age Rating:** Click **Edit** next to Age Rating. Answer "None" to every content description question. This will result in a 4+ rating.
7. **Privacy Policy URL:** Enter the URL to your privacy policy.
8. Click **Save**.

#### Pricing and Availability (left sidebar)
1. Click **Pricing and Availability**.
2. **Price:** Select "Free" (Price Tier 0).
3. **Availability:** All territories (or customize as desired).
4. Click **Save**.

### Step 6: Prepare the Version for Submission

1. Click **iOS App** under the app name in the left sidebar (you should see "1.0 Prepare for Submission").
2. This opens the version page. Fill in all fields:

#### Screenshots
1. Under the **Screenshots** section, you will see tabs for different device sizes.
2. Click on **6.7-inch Display** and drag-and-drop or upload your 6.7-inch screenshots (1290 x 2796 px). Upload them in the order you want them displayed.
3. Click on **6.1-inch Display** and upload your 6.1-inch screenshots (1179 x 2556 px).
4. Repeat for any other device sizes you prepared.

#### Promotional Text
```
See 3 reminders on your Lock Screen, manage the matching list in the app, and keep a simple task streak. No ads, no tracking, no account required.
```

#### Description
Copy and paste the full description from Section 1 of this document.

#### Keywords
```
reminders,widget,lock screen,to do,tasks,checklist,reminder list,productivity,lockscreen,todo
```

#### Support URL
Enter a URL where users can get help. This can be:
- A GitHub repository URL (e.g., `https://github.com/brianpattison/reminders-home-screen-widget`)
- A simple support page on your website
- An email address link

#### Marketing URL (optional)
A link to your app's marketing page, if you have one. You can leave this blank.

#### Build
You will come back to this after uploading a build (Step 7).

#### App Review Information
1. **Sign-In Information:** Leave "Sign-in required" unchecked (no login).
2. **Contact Information:** Enter your name, email, and phone number. Apple may contact you during review.
3. **Notes:** Add the following note to help the reviewer:
   ```
   This app provides a native selected-list companion app and Lock Screen widget for Reminders. To test:
   1. Open the app and grant Reminders access.
   2. Choose a Reminders list in the app.
   3. View the selected list in the app, tap a reminder circle to complete it, and use Settings to choose a streak goal: No Overdue, Daily Progress, or Complete All.
   4. Go to the Lock Screen, long-press, tap Customize, choose Lock Screen, tap Add Widgets.
   5. Find "Reminders Widget" in the widget list and add the rectangular widget.
   The widget will display 3 reminders from the list selected in the app. Tapping the widget opens the Reminders app.
   
   Please ensure you have at least one Reminders list with 3+ items to see the full widget and selected-list view.
   ```

#### Version Release
Under "Version Release," choose one of:
- **Manually release this version** -- You control when the app goes live after approval.
- **Automatically release this version** -- The app goes live as soon as Apple approves it.

### Step 7: Archive and Upload the Build

1. Open the project in Xcode.
2. Connect a physical iOS device, or select **Any iOS Device (arm64)** as the build destination in the toolbar. (You cannot archive for a simulator.)
3. In the menu bar, go to **Product > Archive**.
4. Xcode will build the project and open the **Organizer** window when the archive is complete.
5. In the Organizer, select your new archive and click **Distribute App**.
6. Select **App Store Connect** as the distribution method, then click **Next**.
7. Select **Upload** (not Export), then click **Next**.
8. Leave the default options checked:
   - "Upload your app's symbols..." -- Yes
   - "Manage Version and Build Number" -- Yes
9. Click **Next**. Xcode will sign the app.
10. If prompted to select a signing certificate, choose your distribution certificate (Xcode handles this automatically if you set up automatic signing).
11. Review the summary and click **Upload**.
12. Wait for the upload to complete. This usually takes 1-3 minutes.

### Step 8: Select the Build in App Store Connect

After uploading, the build needs to be processed by Apple. This takes 5-30 minutes.

1. Go back to App Store Connect, to your app's version page.
2. Scroll down to the **Build** section.
3. Once processing completes, click the **+** button next to "Build."
4. Select your uploaded build and click **Done**.
5. If the build does not appear yet, wait and refresh the page. You will also receive an email from Apple when processing finishes (or if there are issues).

### Step 9: Complete the App Privacy Section

1. In the left sidebar, click **App Privacy**.
2. Click **Get Started** (or **Edit** if you have already started).
3. For "Does this app collect any data?", select **No**.
4. Click **Publish**.

### Step 10: Submit for Review

1. Go back to the version page (**iOS App > 1.0 Prepare for Submission**).
2. Verify all fields are filled in:
   - Screenshots uploaded
   - Description, keywords, promotional text entered
   - Build selected
   - App Review notes filled in
   - Contact information provided
   - Support URL entered
3. Click **Add for Review** (the blue button at the top of the page).
4. On the confirmation screen, review your submission and click **Submit to App Review**.

### Step 11: What to Expect During Review

**Timeline:**
- Most apps are reviewed within 24-48 hours. Some reviews happen in under 12 hours.
- If you submit on a weekend or holiday, expect slight delays.

**Possible Outcomes:**

1. **Approved** -- You will receive an email. If you chose automatic release, the app goes live immediately. If manual, go to App Store Connect and click "Release This Version."

2. **Rejected** -- You will receive an email with the specific reason(s). Common rejection reasons for widget apps:
   - **Guideline 4.2 (Minimum Functionality):** Apple may argue the app does not do enough. The app review notes you provided should help here, but if rejected, emphasize in your appeal that the app provides a Lock Screen widget with functionality (3 reminders) that the built-in widget does not offer.
   - **Guideline 2.3 (Accurate Metadata):** Make sure screenshots accurately reflect the actual widget appearance.
   - **Guideline 5.1.1 (Data Collection and Storage):** Ensure you have a privacy policy URL entered, even though you collect no data.

3. **In Review** -- The status changes from "Waiting for Review" to "In Review." You cannot make changes during this time.

**If Rejected:**
1. Read the rejection reason carefully in the Resolution Center (App Store Connect > your app > Resolution Center).
2. You can reply to the reviewer directly in the Resolution Center to ask for clarification or make your case.
3. To resubmit, fix the issue, upload a new build if needed, and click "Submit to App Review" again.

**After Approval:**
- The app typically appears in App Store search results within a few hours of release.
- You can update the Promotional Text at any time without a new review.
- To release an update, increment the version number in `project.yml` (e.g., from `1.0` to `1.1`), archive, upload, and submit a new version.

---

## 5. Quick Reference -- All Metadata at a Glance

| Field | Value |
|---|---|
| App Name | Reminders Widget |
| Subtitle | 3 Reminders on Lock Screen |
| Bundle ID | com.brianpattison.RemindersWidget |
| SKU | reminders-widget-001 |
| Primary Category | Productivity |
| Secondary Category | Utilities |
| Price | Free |
| Age Rating | 4+ |
| Copyright | 2026 Brian Pattison |
| Privacy | No Data Collected |
| Minimum iOS Version | 17.0 |
