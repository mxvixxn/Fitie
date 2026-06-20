import Foundation

enum ConditionMetric: String, Sendable {
    case mood
    case energy
}

struct ConditionInsight: Equatable, Sendable {
    let habitID: UUID
    let habitName: String
    let metric: ConditionMetric
    let delta: Double          // avg(condition on achieved days) - avg(on other days)
    let sampleAchieved: Int
    let sampleOther: Int
}
