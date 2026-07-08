import Foundation
import UserNotifications

enum NotificationService {
    static func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Replaces this habit's pending reminders with the next 7 days of
    /// one-shot notifications, skipping today when already achieved.
    static func rearmReminder(habitID: UUID, name: String, hour: Int, minute: Int,
                              skipToday: Bool) async {
        await cancelReminder(habitID: habitID)
        let center = UNUserNotificationCenter.current()
        for fire in ReminderPlanner.fireDates(hour: hour, minute: minute,
                                              skipToday: skipToday, now: Date()) {
            let content = UNMutableNotificationContent()
            content.title = "Fitie"
            content.body = "\(name) 할 시간이에요."
            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: fire)
            let request = UNNotificationRequest(
                identifier: "habit-\(habitID.uuidString)-\(Int(fire.timeIntervalSince1970))",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
            try? await center.add(request)
        }
    }

    static func cancelReminder(habitID: UUID) async {
        let center = UNUserNotificationCenter.current()
        let ids = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix("habit-\(habitID.uuidString)") }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
