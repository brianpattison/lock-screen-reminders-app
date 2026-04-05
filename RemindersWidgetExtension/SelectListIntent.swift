import AppIntents
import WidgetKit

struct SelectListIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Reminders List"
    static var description = IntentDescription("Choose which reminders list to display on the Lock Screen.")

    @Parameter(title: "List")
    var reminderList: ReminderListEntity?
}
