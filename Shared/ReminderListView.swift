import SwiftUI

struct ReminderListView: View {
    let reminders: [ReminderItem]

    var body: some View {
        let count = reminders.count
        let textFont: Font = count >= 3 ? .caption : .body
        let circleSize: CGFloat = count >= 3 ? 10 : 13
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
