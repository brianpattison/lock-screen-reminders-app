import SwiftUI

@main
struct RemindersWidgetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { _ in
                    if let url = URL(string: "x-apple-reminderkit://") {
                        UIApplication.shared.open(url)
                    }
                }
        }
    }
}
