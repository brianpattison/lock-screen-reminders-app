import SwiftUI

@main
struct RemindersWidgetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    guard url.scheme == "reminderswidget" else { return }
                    if let remindersURL = URL(string: "x-apple-reminderkit://") {
                        UIApplication.shared.open(remindersURL)
                    }
                }
        }
    }
}
