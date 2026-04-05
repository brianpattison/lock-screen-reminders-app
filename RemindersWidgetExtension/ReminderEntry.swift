import WidgetKit

struct ReminderEntry: TimelineEntry {
    let date: Date
    let reminders: [ReminderItem]
    let state: WidgetState

    enum WidgetState {
        case configured
        case notConfigured
        case noAccess
        case empty
    }
}
