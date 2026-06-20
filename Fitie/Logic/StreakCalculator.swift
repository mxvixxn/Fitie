import Foundation

enum StreakCalculator {
    /// Counts consecutive days (ending today or yesterday) with an achieved result.
    static func current(for habitID: UUID, in results: [DailyResult],
                        calendar: Calendar = .current, now: Date = Date()) -> Int {
        let achievedDays = Set(results
            .filter { $0.habitID == habitID && $0.status == .achieved }
            .map { calendar.startOfDay(for: $0.day) })
        var streak = 0
        var day = calendar.startOfDay(for: now)
        // allow today to be pending without breaking the streak
        if !achievedDays.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        while achievedDays.contains(day) {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }
}
