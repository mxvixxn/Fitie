import Foundation

struct VerificationRule: Codable, Equatable, Sendable {
    var metric: HealthMetric
    var comparison: Comparison
    var target: Double

    init(metric: HealthMetric, comparison: Comparison? = nil, target: Double) {
        self.metric = metric
        self.comparison = comparison ?? metric.defaultComparison
        self.target = target
    }
}
