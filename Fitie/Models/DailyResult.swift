import Foundation
import SwiftData

@Model
final class DailyResult {
    var habitID: UUID
    var day: Date            // start-of-day
    var statusRaw: String
    var measured: Double?
    var sourceRaw: String

    init(habitID: UUID, day: Date, status: HabitStatus, measured: Double?, source: ResultSource) {
        self.habitID = habitID
        self.day = day
        self.statusRaw = status.rawValue
        self.measured = measured
        self.sourceRaw = source.rawValue
    }

    var status: HabitStatus {
        get { HabitStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    var source: ResultSource {
        get { ResultSource(rawValue: sourceRaw) ?? .auto }
        set { sourceRaw = newValue.rawValue }
    }
}

enum ResultSource: String, Codable, Sendable {
    case auto
    case manual
}
