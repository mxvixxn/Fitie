import Foundation

protocol HealthDataSource: Sendable {
    func requestAuthorization() async throws
    /// Returns the measured value for `metric` on the given day, or nil if no data.
    /// For `.sleepStart` the value is minutes-from-midnight of sleep onset.
    func value(for metric: HealthMetric, on day: Date) async throws -> Double?
}
