import WidgetKit

struct ReminderEntry: TimelineEntry {
    let date: Date
    let reminders: [ReminderItem]
    let state: WidgetState
    let firstReminderExternalID: String?

    enum WidgetState {
        case configured
        case notConfigured
        case noAccess
        case empty
    }
}
