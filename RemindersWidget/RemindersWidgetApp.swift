import SwiftUI

@main
struct RemindersWidgetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    guard url.scheme == "reminderswidget" else { return }
                    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                    let reminderID = components?.queryItems?.first(where: { $0.name == "reminder" })?.value
                    let target: URL
                    if let reminderID, let deepLink = URL(string: "x-apple-reminderkit://REMCDReminder/\(reminderID)") {
                        target = deepLink
                    } else if let fallback = URL(string: "x-apple-reminderkit://") {
                        target = fallback
                    } else {
                        return
                    }
                    UIApplication.shared.open(target)
                }
        }
    }
}
