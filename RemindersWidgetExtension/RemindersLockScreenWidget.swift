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
            let url: URL = {
                if let id = entry.firstReminderExternalID {
                    return URL(string: "reminderswidget://open?reminder=\(id)")!
                }
                return URL(string: "reminderswidget://open")!
            }()
            RemindersWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(url)
        }
        .configurationDisplayName("Reminders")
        .description("Display reminders from a chosen list.")
        .supportedFamilies([.accessoryRectangular])
    }
}
