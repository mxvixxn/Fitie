import Foundation

struct TemplatePhraser: InsightPhraser {
    func phrase(_ insight: ConditionInsight) async -> String {
        let metric = insight.metric == .mood ? "기분" : "에너지"
        let direction = insight.delta >= 0 ? "높았어요" : "낮았어요"
        let magnitude = String(format: "%.1f", abs(insight.delta))
        return "\(insight.habitName) 한 날 \(metric)이 평균 \(magnitude)점 \(direction)."
    }
}
