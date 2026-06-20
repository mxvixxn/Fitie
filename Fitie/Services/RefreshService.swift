import Foundation
import SwiftData

@MainActor
final class RefreshService {
    private let health: HealthDataSource
    private let phraser: InsightPhraser

    init(health: HealthDataSource, phraser: InsightPhraser) {
        self.health = health
        self.phraser = phraser
    }

    /// Pulls today's health values, evaluates each active habit, persists DailyResult.
    func refreshToday(context: ModelContext, now: Date = Date()) async throws {
        let today = Calendar.current.startOfDay(for: now)
        let dayIsOver = false   // today is in progress
        let habits = try context.fetch(FetchDescriptor<Habit>()).filter { !$0.isArchived }

        for habit in habits where habit.isActive(on: today) {
            let rule = habit.rule
            let measured = (try? await health.value(for: rule.metric, on: today)) ?? nil
            let status = HabitEvaluator.status(measured: measured, target: rule.target,
                                               comparison: rule.comparison, dayIsOver: dayIsOver)
            Store.upsertDailyResult(context, habitID: habit.id, day: today,
                                    status: status, measured: measured, source: .auto)
        }
        try? context.save()
    }

    /// Recomputes insights over a rolling window and stores a snapshot.
    func recomputeInsights(context: ModelContext, windowDays: Int = 21, now: Date = Date()) async throws {
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .day, value: -windowDays, to: cal.startOfDay(for: now))!
        let results = try context.fetch(FetchDescriptor<DailyResult>(
            predicate: #Predicate { $0.day >= cutoff }))
        let conditions = try context.fetch(FetchDescriptor<ConditionEntry>(
            predicate: #Predicate { $0.day >= cutoff }))
        let habits = try context.fetch(FetchDescriptor<Habit>())
        let names = Dictionary(habits.map { ($0.id, $0.name) }, uniquingKeysWith: { a, _ in a })

        let insights = InsightEngine.insights(results: results, conditions: conditions, habitNames: names)
        var sentences: [String] = []
        for insight in insights { sentences.append(await phraser.phrase(insight)) }

        for old in try context.fetch(FetchDescriptor<InsightSnapshot>()) { context.delete(old) }
        context.insert(InsightSnapshot(generatedAt: now, sentences: sentences))
        try? context.save()
    }
}
