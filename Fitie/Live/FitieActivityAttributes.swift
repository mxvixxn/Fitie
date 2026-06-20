import ActivityKit
import Foundation

struct FitieActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var progress: Double      // 0...1
        var elapsedMinutes: Int
    }
    var habitName: String
    var goalMinutes: Int
}
