import EventKit
import SwiftUI

struct ContentView: View {
    @State private var authStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .reminder)

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checklist")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("Reminders Widget")
                .font(.largeTitle)
                .fontWeight(.bold)

            Group {
                switch authStatus {
                case .fullAccess:
                    instructionsView
                case .denied, .restricted:
                    deniedView
                default:
                    requestAccessView
                }
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .onAppear {
            authStatus = EKEventStore.authorizationStatus(for: .reminder)
        }
    }

    private var instructionsView: some View {
        VStack(spacing: 12) {
            Text("To add the widget:")
                .font(.headline)
                .foregroundStyle(.primary)
            Text("Long press your Lock Screen, tap **Customize**, select the Lock Screen, then tap the widget area below the clock to add the **Reminders** widget. Tap the widget to choose which list to display.")
                .font(.subheadline)
        }
    }

    private var deniedView: some View {
        Text("Reminders access was denied. Go to **Settings → Privacy & Security → Reminders** and enable access for this app.")
            .font(.subheadline)
    }

    private var requestAccessView: some View {
        Button("Grant Reminders Access") {
            Task {
                let store = EKEventStore()
                _ = try? await store.requestFullAccessToReminders()
                authStatus = EKEventStore.authorizationStatus(for: .reminder)
            }
        }
        .buttonStyle(.borderedProminent)
    }
}
