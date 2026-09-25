import Foundation
import Testing
@testable import Fitie

struct StreakCalculatorTests {
    private let cal = Calendar(identifier: .gregorian)
    private let habitID = UUID()

    private func day(_ offset: Int, from now: Date) -> Date {
        cal.startOfDay(for: cal.date(byAdding: .day, value: offset, to: now)!)
    }

    private func achieved(_ offsets: [Int], now: Date) -> [DailyResult] {
        offsets.map {
            DailyResult(habitID: habitID, day: day($0, from: now),
                        status: .achieved, measured: 1, source: .auto)
        }
    }

    @Test func currentCountsBackFromToday() {
        let now = Date()
        let results = achieved([0, -1, -2], now: now)
        #expect(StreakCalculator.current(for: habitID, in: results, calendar: cal, now: now) == 3)
    }

    @Test func currentAllowsTodayPending() {
        let now = Date()
        let results = achieved([-1, -2], now: now)   // today not achieved yet
        #expect(StreakCalculator.current(for: habitID, in: results, calendar: cal, now: now) == 2)
    }

    @Test func currentBreaksOnGap() {
        let now = Date()
        let results = achieved([0, -1, -3, -4], now: now)   // gap at -2
        #expect(StreakCalculator.current(for: habitID, in: results, calendar: cal, now: now) == 2)
    }

    /// Regression guard for the Insights "최장 스트릭" card, which must reflect the longest
    /// historical run — not the current one. After a broken streak, `longest` keeps the past
    /// maximum while `current` drops. (InsightsView previously called `current` by mistake.)
    @Test func longestReflectsPastRunAfterBreak() {
        let now = Date()
        // A 5-day run two weeks ago, broken since; only a 1-day run today.
        let results = achieved([-14, -13, -12, -11, -10, 0], now: now)
        #expect(StreakCalculator.longest(for: habitID, in: results, calendar: cal) == 5)
        #expect(StreakCalculator.current(for: habitID, in: results, calendar: cal, now: now) == 1)
    }

    @Test func longestIsZeroWithNoAchievements() {
        #expect(StreakCalculator.longest(for: habitID, in: [], calendar: cal) == 0)
    }
}
