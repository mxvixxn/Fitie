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

    @Test func manualResultIsNotOverwrittenByAutoRefresh() async throws {
        let container = Store.inMemoryContainer()
        let context = container.mainContext
        let habit = Habit(name: "걷기", emoji: "", colorHex: "",
                          rule: VerificationRule(metric: .steps, target: 5000))
        context.insert(habit)
        // User manually marked today as achieved (e.g. HealthKit denied).
        Store.upsertDailyResult(context, habitID: habit.id, day: Date(),
                                status: .achieved, measured: 1, source: .manual)

        let health = MockHealthDataSource(scripted: [.steps: 100])
        let service = RefreshService(health: health, phraser: TemplatePhraser())
        try await service.refreshToday(context: context)

        let result = try context.fetch(FetchDescriptor<DailyResult>()).first
        #expect(result?.status == .achieved)
        #expect(result?.source == .manual)
    }

    @Test func uncheckedManualHabitBecomesMissedWhenDayIsOver() async throws {
        let container = Store.inMemoryContainer()
        let context = container.mainContext
        let habit = Habit(name: "독서", emoji: "", colorHex: "",
                          rule: VerificationRule(metric: .manual, target: 1))
        context.insert(habit)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1,
                                              to: Calendar.current.startOfDay(for: Date()))!
        let service = RefreshService(health: MockHealthDataSource(scripted: [:]),
                                     phraser: TemplatePhraser())
        try await service.refresh(day: yesterday, dayIsOver: true, context: context)

        let result = try context.fetch(FetchDescriptor<DailyResult>()).first
        #expect(result?.day == yesterday)
        #expect(result?.status == .missed)
    }

    @Test func manualHabitStaysUntouchedWhileDayInProgress() async throws {
        let container = Store.inMemoryContainer()
        let context = container.mainContext
        let habit = Habit(name: "독서", emoji: "", colorHex: "",
                          rule: VerificationRule(metric: .manual, target: 1))
        context.insert(habit)

        let service = RefreshService(health: MockHealthDataSource(scripted: [:]),
                                     phraser: TemplatePhraser())
        try await service.refreshToday(context: context)

        #expect(try context.fetch(FetchDescriptor<DailyResult>()).isEmpty)
    }

    @Test func finalizePastDaysMarksMissedYesterday() async throws {
        let container = Store.inMemoryContainer()
        let context = container.mainContext
        let habit = Habit(name: "걷기", emoji: "", colorHex: "",
                          rule: VerificationRule(metric: .steps, target: 5000))
        context.insert(habit)

        let cal = Calendar.current
        let yesterday = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: Date()))!
        let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: cal.startOfDay(for: Date()))!

        let service = RefreshService(health: MockHealthDataSource(scripted: [.steps: 1000]),
                                     phraser: TemplatePhraser())
        let finalized = try await service.finalizePastDays(context: context,
                                                           lastFinalizedDay: twoDaysAgo)

        #expect(finalized == yesterday)
        let result = try context.fetch(FetchDescriptor<DailyResult>()).first
        #expect(result?.day == yesterday)
        #expect(result?.status == .missed)   // 1000 < 5000 and the day is over
    }

    @Test func finalizePastDaysReturnsNilWhenUpToDate() async throws {
        let container = Store.inMemoryContainer()
        let context = container.mainContext
        let cal = Calendar.current
        let yesterday = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: Date()))!

        let service = RefreshService(health: MockHealthDataSource(scripted: [:]),
                                     phraser: TemplatePhraser())
        let finalized = try await service.finalizePastDays(context: context,
                                                           lastFinalizedDay: yesterday)
        #expect(finalized == nil)
    }

    @Test func finalizePastDaysClampsStaleAnchorToSevenDays() async throws {
        let container = Store.inMemoryContainer()
        let context = container.mainContext
        let habit = Habit(name: "걷기", emoji: "", colorHex: "",
                          rule: VerificationRule(metric: .steps, target: 5000))
        context.insert(habit)

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let staleAnchor = cal.date(byAdding: .day, value: -30, to: today)!
        // Same lower bound the nil-anchor branch already clamps to.
        let earliestExpectedDay = cal.date(byAdding: .day, value: -7, to: today)!
            .addingTimeInterval(24 * 60 * 60)

        let service = RefreshService(health: MockHealthDataSource(scripted: [.steps: 1000]),
                                     phraser: TemplatePhraser())
        let finalized = try await service.finalizePastDays(context: context,
                                                           lastFinalizedDay: staleAnchor)

        #expect(finalized == yesterday)
        let results = try context.fetch(FetchDescriptor<DailyResult>())
        // A 30-day-old anchor must not finalize all 30 days — only the trailing
        // 7-day window, matching the nil-anchor branch's own safeguard.
        #expect(results.count == 6)
        #expect(results.map(\.day).min() == earliestExpectedDay)
    }
}
