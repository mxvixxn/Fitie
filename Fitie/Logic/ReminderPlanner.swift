import Foundation

enum ReminderPlanner {
    /// Concrete fire dates for the next `days` days at hour:minute.
    /// Today is dropped when its time already passed or `skipToday` is set
    /// (habit already achieved).
    static func fireDates(hour: Int, minute: Int, skipToday: Bool,
                          now: Date, days: Int = 7,
                          calendar: Calendar = .current) -> [Date] {
        var dates: [Date] = []
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: offset,
                                          to: calendar.startOfDay(for: now)),
                  let fire = calendar.date(bySettingHour: hour, minute: minute,
                                           second: 0, of: day) else { continue }
            if offset == 0 && (skipToday || fire <= now) { continue }
            dates.append(fire)
        }
        return dates
    }
}
