import Foundation
import Testing
@testable import Fitie

struct ReminderPlannerTests {
    private let cal = Calendar.current
    private var nineAM: Date {
        cal.date(bySettingHour: 9, minute: 0, second: 0, of: cal.startOfDay(for: Date()))!
    }

    @Test func includesTodayWhenTimeIsAhead() {
        let dates = ReminderPlanner.fireDates(hour: 23, minute: 59, skipToday: false, now: nineAM)
        #expect(dates.count == 7)
        #expect(cal.isDate(dates[0], inSameDayAs: nineAM))
    }

    @Test func skipsTodayWhenTimeHasPassed() {
        let dates = ReminderPlanner.fireDates(hour: 8, minute: 0, skipToday: false, now: nineAM)
        #expect(dates.count == 6)
        #expect(!cal.isDate(dates[0], inSameDayAs: nineAM))
    }

    @Test func skipsTodayWhenAlreadyAchieved() {
        let dates = ReminderPlanner.fireDates(hour: 23, minute: 59, skipToday: true, now: nineAM)
        #expect(dates.count == 6)
    }
}
