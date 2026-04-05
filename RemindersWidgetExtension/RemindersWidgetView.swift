import SwiftUI
import WidgetKit

struct RemindersWidgetView: View {
    let entry: ReminderEntry

    var body: some View {
        switch entry.state {
        case .notConfigured:
            Text("Customize Lock Screen to set list")
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
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(entry.reminders.enumerated()), id: \.offset) { _, reminder in
                    HStack(spacing: 4) {
                        Image(systemName: "circle")
                            .font(.system(size: 10))
                        Text(reminder.title)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
