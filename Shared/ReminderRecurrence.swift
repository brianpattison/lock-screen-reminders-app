import Foundation

enum ReminderRecurrence: Equatable {
    case interval(frequency: Frequency, count: Int)
    case complex

    enum Frequency {
        case daily, weekly, monthly, yearly
    }

    var displayText: String {
        switch self {
        case .complex:
            return "Repeats"
        case let .interval(frequency, count):
            if count <= 1 {
                switch frequency {
                case .daily: return "Daily"
                case .weekly: return "Weekly"
                case .monthly: return "Monthly"
                case .yearly: return "Yearly"
                }
            }
            switch frequency {
            case .daily: return "Every \(count) days"
            case .weekly: return "Every \(count) weeks"
            case .monthly: return "Every \(count) months"
            case .yearly: return "Every \(count) years"
            }
        }
    }
}
