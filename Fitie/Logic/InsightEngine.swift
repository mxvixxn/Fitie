import Foundation

enum InsightEngine {
    static let minSamplePerGroup = 3
    static let maxInsights = 3

    static func insights(results: [DailyResult],
                         conditions: [ConditionEntry],
                         habitNames: [UUID: String],
                         calendar: Calendar = .current) -> [ConditionInsight] {
        let conditionByDay: [Date: ConditionEntry] = Dictionary(
            conditions.map { (calendar.startOfDay(for: $0.day), $0) },
            uniquingKeysWith: { a, _ in a }
        )

        let resultsByHabit = Dictionary(grouping: results, by: { $0.habitID })
        var out: [ConditionInsight] = []

        for (habitID, habitResults) in resultsByHabit {
            guard let name = habitNames[habitID] else { continue }
            for metric in [ConditionMetric.mood, .energy] {
                var achieved: [Double] = []
                var other: [Double] = []
                for r in habitResults {
                    guard let c = conditionByDay[calendar.startOfDay(for: r.day)] else { continue }
                    let value = Double(metric == .mood ? c.mood : c.energy)
                    if r.status == .achieved { achieved.append(value) } else { other.append(value) }
                }
                guard achieved.count >= minSamplePerGroup, other.count >= minSamplePerGroup else { continue }
                let delta = mean(achieved) - mean(other)
                out.append(ConditionInsight(habitID: habitID, habitName: name, metric: metric,
                                            delta: delta, sampleAchieved: achieved.count,
                                            sampleOther: other.count))
            }
        }

        return out
            .sorted { (abs($0.delta), $0.sampleAchieved) > (abs($1.delta), $1.sampleAchieved) }
            .prefix(maxInsights)
            .map { $0 }
    }

    private static func mean(_ xs: [Double]) -> Double {
        xs.isEmpty ? 0 : xs.reduce(0, +) / Double(xs.count)
    }
}
