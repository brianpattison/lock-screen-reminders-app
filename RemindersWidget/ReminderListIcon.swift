import SwiftUI

struct ReminderListIcon: View {
    @Environment(\.colorScheme) private var colorScheme

    private var iconColor: Color {
        colorScheme == .dark
            ? Color(red: 225 / 255, green: 175 / 255, blue: 68 / 255)
            : Color(red: 16 / 255, green: 34 / 255, blue: 66 / 255)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            row(lineWidth: 34)
            row(lineWidth: 48)
            row(lineWidth: 62)
        }
    }

    private func row(lineWidth: CGFloat) -> some View {
        HStack(spacing: 7) {
            Circle()
                .stroke(iconColor, lineWidth: 2.5)
                .frame(width: 16, height: 16)
            RoundedRectangle(cornerRadius: 3.5)
                .fill(iconColor)
                .frame(width: lineWidth, height: 7)
        }
    }
}
