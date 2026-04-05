import SwiftUI
import WidgetKit

struct RemindersLockScreenWidget: Widget {
    static let widgetOpenURL = URL(string: "reminderswidget://open")!
    let kind = "RemindersLockScreenWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectListIntent.self,
            provider: RemindersTimelineProvider()
        ) { entry in
            RemindersWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(Self.widgetOpenURL)
        }
        .configurationDisplayName("Reminders")
        .description("Display reminders from a chosen list.")
        .supportedFamilies([.accessoryRectangular])
    }
}
