import Foundation

struct SelectedListStore {
    static let todayID = "com.brianpattison.RemindersWidget.today"

    private static let suiteName = "group.com.brianpattison.RemindersWidget"
    private static let listIDKey = "selectedListID"
    private static let listTitleKey = "selectedListTitle"

    private let defaults: UserDefaults

    init(defaults: UserDefaults? = nil) {
        if let defaults {
            self.defaults = defaults
        } else if let shared = UserDefaults(suiteName: Self.suiteName) {
            self.defaults = shared
        } else {
            assertionFailure("Failed to create UserDefaults for App Group suite: \(Self.suiteName)")
            self.defaults = .standard
        }
    }

    var selectedListID: String? {
        get { defaults.string(forKey: Self.listIDKey) }
        set { defaults.set(newValue, forKey: Self.listIDKey) }
    }

    var selectedListTitle: String? {
        get { defaults.string(forKey: Self.listTitleKey) }
        set { defaults.set(newValue, forKey: Self.listTitleKey) }
    }
}
