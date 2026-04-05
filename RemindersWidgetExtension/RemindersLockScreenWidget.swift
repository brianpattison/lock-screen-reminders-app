import SwiftUI
import WidgetKit

struct RemindersLockScreenWidget: Widget {
    let kind = "RemindersLockScreenWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectListIntent.self,
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
