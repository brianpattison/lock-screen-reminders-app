import XCTest

final class SelectedListStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: SelectedListStore!

    override func setUp() {
        super.setUp()
        suiteName = "test-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        store = SelectedListStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testDefaultsToNil() {
        XCTAssertNil(store.selectedListID)
        XCTAssertNil(store.selectedListTitle)
    }

    func testPersistsSelectedList() {
        store.selectedListID = "calendar-123"
        store.selectedListTitle = "Groceries"

        XCTAssertEqual(store.selectedListID, "calendar-123")
        XCTAssertEqual(store.selectedListTitle, "Groceries")
    }

    func testPersistsAcrossInstances() {
        store.selectedListID = "calendar-456"
        store.selectedListTitle = "Work"

        let store2 = SelectedListStore(defaults: defaults)
        XCTAssertEqual(store2.selectedListID, "calendar-456")
        XCTAssertEqual(store2.selectedListTitle, "Work")
    }

    func testTodayID() {
        XCTAssertEqual(SelectedListStore.todayID, "com.brianpattison.RemindersWidget.today")
    }
}
