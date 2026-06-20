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

    /// The longest run of consecutive achieved days ever recorded for a habit.
    static func longest(for habitID: UUID, in results: [DailyResult],
                        calendar: Calendar = .current) -> Int {
        let days = Set(results
            .filter { $0.habitID == habitID && $0.status == .achieved }
            .map { calendar.startOfDay(for: $0.day) })
        var best = 0
        for day in days {
            // only start counting from the beginning of a run
            let previous = calendar.date(byAdding: .day, value: -1, to: day)!
            if days.contains(previous) { continue }
            var length = 0
            var cursor = day
            while days.contains(cursor) {
                length += 1
                cursor = calendar.date(byAdding: .day, value: 1, to: cursor)!
            }
            best = max(best, length)
        }
        return best
    }
}
