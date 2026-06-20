import Foundation
import SwiftData

@Model
final class ConditionEntry {
    var day: Date            // start-of-day
    var mood: Int            // 1...5
    var energy: Int          // 1...5
    var note: String

    init(day: Date, mood: Int, energy: Int, note: String = "") {
        self.day = day
        self.mood = mood
        self.energy = energy
        self.note = note
    }
}
