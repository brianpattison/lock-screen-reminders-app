import SwiftUI
import WidgetKit

struct RemindersWidgetView: View {
    let entry: ReminderEntry

    var body: some View {
        switch entry.state {
        case .notConfigured:
            Text("Open app to select a list")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .noAccess:
            Text("Open app to grant Reminders access")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .empty:
            Text("No reminders")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .configured:
            ReminderListView(reminders: entry.reminders)
        }
    }
}
