import Foundation

enum HabitStatus: String, Codable, Sendable {
    case achieved
    case inProgress
    case pending
    case missed
}
