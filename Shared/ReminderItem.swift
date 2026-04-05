import Foundation

struct ReminderItem {
    let title: String
    let dueDate: Date?
    let creationDate: Date?
    let externalID: String?
}

func sortReminders(_ reminders: [ReminderItem]) -> [ReminderItem] {
    reminders.sorted { r1, r2 in
        switch (r1.dueDate, r2.dueDate) {
        case let (d1?, d2?):
            return d1 < d2
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            let c1 = r1.creationDate ?? .distantPast
            let c2 = r2.creationDate ?? .distantPast
            return c1 < c2
        }
    }
}
