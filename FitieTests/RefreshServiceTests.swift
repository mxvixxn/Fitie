import Foundation
import SwiftData
import Testing
@testable import Fitie

@MainActor
struct RefreshServiceTests {
    @Test func writesAchievedResultWhenTargetMet() async throws {
        let container = Store.inMemoryContainer()
        let context = container.mainContext
        let habit = Habit(name: "걷기", emoji: "🚶", colorHex: "#1D9E75",
                          rule: VerificationRule(metric: .steps, target: 5000))
        context.insert(habit)

        let health = MockHealthDataSource(scripted: [.steps: 6000])
        let service = RefreshService(health: health, phraser: TemplatePhraser())

        try await service.refreshToday(context: context)

        let results = try context.fetch(FetchDescriptor<DailyResult>())
        #expect(results.count == 1)
        #expect(results.first?.status == .achieved)
        #expect(results.first?.measured == 6000)
    }

    @Test func writesPendingWhenNoData() async throws {
        let container = Store.inMemoryContainer()
        let context = container.mainContext
        let habit = Habit(name: "물", emoji: "💧", colorHex: "#185FA5",
                          rule: VerificationRule(metric: .water, target: 8))
        context.insert(habit)

        let health = MockHealthDataSource(scripted: [.water: nil])
        let service = RefreshService(health: health, phraser: TemplatePhraser())

        try await service.refreshToday(context: context)
        let results = try context.fetch(FetchDescriptor<DailyResult>())
        #expect(results.first?.status == .pending)
    }
}
