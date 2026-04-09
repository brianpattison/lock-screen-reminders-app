import SwiftUI
import WidgetKit

struct RemindersLockScreenWidget: Widget {
    let kind = "RemindersLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: RemindersTimelineProvider()
        ) { entry in
            RemindersWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Reminders")
        .description("Display reminders from a chosen list.")
        .supportedFamilies([.accessoryRectangular])
    }
}
