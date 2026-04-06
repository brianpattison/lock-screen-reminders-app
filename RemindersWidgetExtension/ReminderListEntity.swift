import AppIntents
@preconcurrency import EventKit

struct ReminderListEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Reminder List"
    static var defaultQuery = ReminderListQuery()

    static let todayID = "com.brianpattison.RemindersWidget.today"
    static let today = ReminderListEntity(id: todayID, title: "Today")

    var id: String
    var title: String

    var isToday: Bool { id == Self.todayID }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct ReminderListQuery: EntityQuery {
    private nonisolated(unsafe) let store = EKEventStore()

    func entities(for identifiers: [String]) async throws -> [ReminderListEntity] {
        var results: [ReminderListEntity] = []
        if identifiers.contains(ReminderListEntity.todayID) {
            results.append(.today)
        }
        results += store.calendars(for: .reminder)
            .filter { identifiers.contains($0.calendarIdentifier) }
            .map { ReminderListEntity(id: $0.calendarIdentifier, title: $0.title) }
        return results
    }

    func suggestedEntities() async throws -> [ReminderListEntity] {
        let calendars = store.calendars(for: .reminder)
            .map { ReminderListEntity(id: $0.calendarIdentifier, title: $0.title) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        return [.today] + calendars
    }

    func defaultResult() async -> ReminderListEntity? {
        return .today
    }
}
