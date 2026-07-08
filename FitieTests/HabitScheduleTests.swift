import Foundation
import Testing
@testable import Fitie

struct HabitScheduleTests {
    private func date(weekday: Int) -> Date {
        // 2026-07-05 is a Sunday (weekday 1); offset to reach the target weekday.
        let base = Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 5))!
        return Calendar.current.date(byAdding: .day, value: weekday - 1, to: base)!
    }

    @Test func emptyWeekdaysMeansEveryDay() {
        let habit = Habit(name: "걷기", emoji: "", colorHex: "",
                          rule: VerificationRule(metric: .steps, target: 1))
        #expect(habit.isActive(on: date(weekday: 1)))
        #expect(habit.isActive(on: date(weekday: 4)))
    }

    @Test func activeOnlyOnSelectedWeekdays() {
        let habit = Habit(name: "운동", emoji: "", colorHex: "",
                          rule: VerificationRule(metric: .exerciseMinutes, target: 20),
                          activeWeekdays: [2, 4, 6])   // Mon, Wed, Fri
        #expect(habit.isActive(on: date(weekday: 2)))
        #expect(!habit.isActive(on: date(weekday: 1)))
    }
}
