import Foundation

final class MockHealthDataSource: HealthDataSource, @unchecked Sendable {
    var scripted: [HealthMetric: Double?]
    var authorized = false

    init(scripted: [HealthMetric: Double?] = [:]) {
        self.scripted = scripted
    }

    func requestAuthorization() async throws { authorized = true }

    func value(for metric: HealthMetric, on day: Date) async throws -> Double? {
        scripted[metric] ?? nil
    }
}
