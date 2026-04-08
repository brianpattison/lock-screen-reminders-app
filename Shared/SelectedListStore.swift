import Foundation

struct SelectedListStore {
    static let todayID = "com.brianpattison.RemindersWidget.today"

    private static let suiteName = "group.com.brianpattison.RemindersWidget"
    private static let listIDKey = "selectedListID"
    private static let listTitleKey = "selectedListTitle"

    private let defaults: UserDefaults

    init(defaults: UserDefaults? = nil) {
        self.defaults = defaults ?? UserDefaults(suiteName: Self.suiteName) ?? .standard
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
