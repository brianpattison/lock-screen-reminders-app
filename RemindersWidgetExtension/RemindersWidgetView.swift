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
            let count = entry.reminders.count
            let textFont: Font = count >= 3 ? .caption : .body
            let circleSize: CGFloat = count >= 3 ? 10 : 13
            VStack(alignment: .leading, spacing: count >= 3 ? 2 : 6) {
                ForEach(Array(entry.reminders.enumerated()), id: \.offset) { _, reminder in
                    Link(destination: reminder.widgetURL) {
                        HStack(spacing: 5) {
                            Image(systemName: "circle")
                                .font(.system(size: circleSize))
                            Text(reminder.title)
                                .font(textFont)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
