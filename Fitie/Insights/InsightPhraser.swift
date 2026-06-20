import Foundation

protocol InsightPhraser: Sendable {
    func phrase(_ insight: ConditionInsight) async -> String
}
