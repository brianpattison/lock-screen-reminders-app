import SwiftUI

struct ReminderListView: View {
    let reminders: [ReminderItem]

    var body: some View {
        let count = reminders.count
        let hasLongTitle = reminders.contains { $0.title.count > 20 }
        let useSmallFont = count >= 3 || hasLongTitle
        let textFont: Font = useSmallFont ? .caption : .body
        let circleSize: CGFloat = useSmallFont ? 10 : 13
        VStack(alignment: .leading, spacing: count >= 3 ? 2 : 6) {
            ForEach(Array(reminders.enumerated()), id: \.offset) { _, reminder in
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
