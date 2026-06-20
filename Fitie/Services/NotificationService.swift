import Foundation
import UserNotifications

enum NotificationService {
    static func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func scheduleReminder(habitID: UUID, name: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Fitie"
        content.body = "\(name) 할 시간이에요."
        var date = DateComponents(); date.hour = hour; date.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: "habit-\(habitID.uuidString)",
                                            content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelReminder(habitID: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["habit-\(habitID.uuidString)"])
    }
}
