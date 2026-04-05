import AppIntents
import EventKit

struct ReminderListEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Reminder List"
    static var defaultQuery = ReminderListQuery()

    var id: String
    var title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct ReminderListQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ReminderListEntity] {
        let store = EKEventStore()
        return store.calendars(for: .reminder)
            .filter { identifiers.contains($0.calendarIdentifier) }
            .map { ReminderListEntity(id: $0.calendarIdentifier, title: $0.title) }
    }

    func suggestedEntities() async throws -> [ReminderListEntity] {
        let store = EKEventStore()
        return store.calendars(for: .reminder)
            .map { ReminderListEntity(id: $0.calendarIdentifier, title: $0.title) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
}
