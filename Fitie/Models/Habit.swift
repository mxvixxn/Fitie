import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var emoji: String
    var colorHex: String
    var ruleData: Data
    var activeWeekdays: [Int]   // 1=Sun ... 7=Sat; empty means every day
    var reminderHour: Int?
    var reminderMinute: Int?
    var createdAt: Date
    var isArchived: Bool

    init(name: String, emoji: String, colorHex: String, rule: VerificationRule,
         activeWeekdays: [Int] = [], reminderHour: Int? = nil, reminderMinute: Int? = nil) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.ruleData = (try? JSONEncoder().encode(rule)) ?? Data()
        self.activeWeekdays = activeWeekdays
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.createdAt = Date()
        self.isArchived = false
    }

    var rule: VerificationRule {
        get {
            (try? JSONDecoder().decode(VerificationRule.self, from: ruleData))
                ?? VerificationRule(metric: .steps, target: 1)
        }
        set { ruleData = (try? JSONEncoder().encode(newValue)) ?? ruleData }
    }

    func isActive(on date: Date, calendar: Calendar = .current) -> Bool {
        guard !activeWeekdays.isEmpty else { return true }
        return activeWeekdays.contains(calendar.component(.weekday, from: date))
    }
}
